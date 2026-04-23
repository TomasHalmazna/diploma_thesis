// app.js

const functionSelect = document.getElementById('functionSelect');
const dimInput = document.getElementById('dimInput');
const x0Inputs = document.getElementById('x0Inputs');
const axisX = document.getElementById('axisX');
const axisY = document.getElementById('axisY');
const plotDiv = document.getElementById('plotDiv');
let debounceTimer;

document.addEventListener('DOMContentLoaded', () => {
    updateDimensions();
});

function updateDimensions() {
    const func = functionSelect.value;
    let N = parseInt(dimInput.value);
    
    if (func === 'himmelblau') {
        document.getElementById('dimensionGroup').classList.add('hidden');
        document.getElementById('customGroup').classList.add('hidden');
        N = 2;
    } else if (func === 'custom') {
        document.getElementById('dimensionGroup').classList.remove('hidden');
        document.getElementById('customGroup').classList.remove('hidden');
        N = parseInt(dimInput.value);
    } else {
        document.getElementById('dimensionGroup').classList.remove('hidden');
        document.getElementById('customGroup').classList.add('hidden');
    }

    x0Inputs.innerHTML = '';
    axisX.innerHTML = '';
    axisY.innerHTML = '';
    
    for(let i = 1; i <= N; i++) {
        let val = 0.0;
        if (func === 'rosenbrock' && i === 1) val = -1.0;
        if (func === 'himmelblau' && i === 1) val = -0.27;
        if (func === 'himmelblau' && i === 2) val = -0.9;
        if (func === 'sphere') { val = (i % 2 === 0) ? 3.0 : -4.0; } 

        x0Inputs.innerHTML += `<div class="dim-box">x<sub>${i}</sub>: <input type="number" id="x0_${i}" value="${val}" step="0.5"></div>`;
        axisX.innerHTML += `<option value="${i}">x${i}</option>`;
        axisY.innerHTML += `<option value="${i}" ${i === 2 ? 'selected' : ''}>x${i}</option>`;
    }

    drawInitialPlot();
}

dimInput.addEventListener('change', updateDimensions);
functionSelect.addEventListener('change', updateDimensions);

document.getElementById('logScaleCb').addEventListener('change', function() {
    const type = this.checked ? 'log' : 'linear';
    if (document.getElementById('fPlotDiv').data) Plotly.relayout('fPlotDiv', {'yaxis.type': type});
    if (document.getElementById('gradPlotDiv').data) Plotly.relayout('gradPlotDiv', {'yaxis.type': type});
    if (document.getElementById('alphaPlotDiv').data) Plotly.relayout('alphaPlotDiv', {'yaxis.type': type});
});

document.getElementById('equalAxesCb').addEventListener('change', function() {
    const update = {};
    if (this.checked) {
        update['yaxis.scaleanchor'] = 'x';
        update['yaxis.scaleratio'] = 1;
    } else {
        update['yaxis.scaleanchor'] = null;
    }
    if (plotDiv.data) {
        Plotly.relayout(plotDiv, update);
    }
});

function attachRelayoutListener() {
    if (plotDiv.removeAllListeners) {
        plotDiv.removeAllListeners('plotly_relayout');
    }

    plotDiv.on('plotly_relayout', function(eventdata) {
        if (!eventdata['xaxis.range[0]'] && !eventdata['xaxis.range'] && !eventdata['xaxis.autorange'] &&
            !eventdata['yaxis.range[0]'] && !eventdata['yaxis.range'] && !eventdata['yaxis.autorange']) {
            return; 
        }

        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(() => {
            try {
                const xmin = plotDiv.layout.xaxis.range[0];
                const xmax = plotDiv.layout.xaxis.range[1];
                const ymin = plotDiv.layout.yaxis.range[0];
                const ymax = plotDiv.layout.yaxis.range[1];

                fetchNewContours(xmin, xmax, ymin, ymax);
            } catch(e) {
                console.warn("Could not read ranges for contour update.");
            }
        }, 400); 
    });
}

async function fetchNewContours(xmin, xmax, ymin, ymax) {
    document.getElementById('loadingText').innerText = "Recalculating View...";
    document.getElementById('loadingOverlay').classList.add('active');

    const func = functionSelect.value;
    const N = func === 'himmelblau' ? 2 : parseInt(dimInput.value);
    let x0_arr = [];
    for(let i=1; i<=N; i++) {
        const el = document.getElementById(`x0_${i}`);
        x0_arr.push(el ? el.value : "0.0");
    }
    const x0_str = x0_arr.join(",");
    const customFormula = func === 'custom' ? document.getElementById('customFormula').value : "";

    const url = `http://127.0.0.1:8080/contours?function=${func}&custom_formula=${encodeURIComponent(customFormula)}&xmin=${xmin}&xmax=${xmax}&ymin=${ymin}&ymax=${ymax}&dim_x=${axisX.value}&dim_y=${axisY.value}&x0=${x0_str}`;
    
    try {
        const res = await fetch(url);
        const data = await res.json();
        
        if (data.contour_z && plotDiv.data && plotDiv.data.length > 0) {
            plotDiv.data[0].x = data.contour_x;
            plotDiv.data[0].y = data.contour_y;
            plotDiv.data[0].z = data.contour_z;
            Plotly.redraw(plotDiv);
        }
    } catch (error) {
        console.error("Failed to fetch new contours:", error);
    } finally {
        document.getElementById('loadingOverlay').classList.remove('active');
        document.getElementById('loadingText').innerText = "Optimizing... Please wait";
    }
}

async function drawInitialPlot() {
    const func = functionSelect.value;
    if (func === 'custom' && !document.getElementById('customFormula').value.trim()) {
        Plotly.newPlot('plotDiv', [], {title: "Awaiting custom formula..."});
        return;
    }

    let xmin = -5, xmax = 5, ymin = -5, ymax = 5;
    if (func === 'rosenbrock') { xmin = -2; xmax = 2; ymin = -1; ymax = 3; }

    const N = func === 'himmelblau' ? 2 : parseInt(dimInput.value);
    let x0_arr = [];
    for(let i=1; i<=N; i++) {
        const el = document.getElementById(`x0_${i}`);
        x0_arr.push(el ? el.value : "0.0");
    }
    const x0_str = x0_arr.join(",");
    const customFormula = func === 'custom' ? document.getElementById('customFormula').value : "";

    const url = `http://127.0.0.1:8080/contours?function=${func}&custom_formula=${encodeURIComponent(customFormula)}&xmin=${xmin}&xmax=${xmax}&ymin=${ymin}&ymax=${ymax}&dim_x=${axisX.value}&dim_y=${axisY.value}&x0=${x0_str}`;
    
    try {
        const res = await fetch(url);
        const data = await res.json();
        
        if(data.error || !data.contour_z) {
            Plotly.newPlot('plotDiv', [], {title: "Function definition invalid or incomplete."});
            return;
        }

        const contourTrace = {
            z: data.contour_z,
            x: data.contour_x,
            y: data.contour_y,
            type: 'contour',
            colorscale: 'YlGnBu',
            ncontours: 40,
            line: { smoothing: 1.3, color: 'rgba(0,0,0,0.3)', width: 0.8 },
            contours: { coloring: 'heatmap' },
            name: 'Contours'
        };

        const layout = {
            title: `${functionSelect.options[functionSelect.selectedIndex].text} Slice (x${axisX.value}, x${axisY.value})`,
            xaxis: { title: `x${axisX.value}`, range: [xmin, xmax] },
            yaxis: { title: `x${axisY.value}`, range: [ymin, ymax] }
        };

        Plotly.newPlot('plotDiv', [contourTrace], layout);
        attachRelayoutListener();

    } catch(e) {
        console.error("Failed to load initial plot", e);
    }
}

const methodSelect = document.getElementById('methodSelect');
const cgVariantGroup = document.getElementById('cgVariantGroup');
const lbfgsOptionsGroup = document.getElementById('lbfgsOptionsGroup');

methodSelect.addEventListener('change', () => {
    cgVariantGroup.classList.add('hidden');
    lbfgsOptionsGroup.classList.add('hidden');
    if (methodSelect.value === 'cg') cgVariantGroup.classList.remove('hidden');
    else if (methodSelect.value === 'lbfgs') lbfgsOptionsGroup.classList.remove('hidden');
});

const lsSelect = document.getElementById('lsSelect');
const exactLsOptionsGroup = document.getElementById('exactLsOptionsGroup');
const autoBracketCb = document.getElementById('autoBracketCb');
const manualIntervalDiv = document.getElementById('manualIntervalDiv');
const exactMethods = ['gss', 'dichotomous', 'quadratic', 'brent'];

lsSelect.addEventListener('change', () => {
    if (exactMethods.includes(lsSelect.value)) exactLsOptionsGroup.classList.remove('hidden');
    else exactLsOptionsGroup.classList.add('hidden');
});

autoBracketCb.addEventListener('change', () => {
    if (autoBracketCb.checked) manualIntervalDiv.classList.add('hidden');
    else manualIntervalDiv.classList.remove('hidden');
});

document.getElementById('fDetails').addEventListener('toggle', function() { if(this.open) Plotly.Plots.resize('fPlotDiv'); });
document.getElementById('gradDetails').addEventListener('toggle', function() { if(this.open) Plotly.Plots.resize('gradPlotDiv'); });
document.getElementById('alphaDetails').addEventListener('toggle', function() { if(this.open) Plotly.Plots.resize('alphaPlotDiv'); });

const modalContent = {
    function: {
        rosenbrock: {
            title: "Rosenbrock Function",
            body: `<p>Also known as the Valley or Banana function, it is a popular test problem for gradient-based optimization algorithms.</p>
                   <div class="formula-box">
                       $$f(\\mathbf{x}) = \\sum_{i=1}^{n-1} \\left[ 100(x_{i+1} - x_i^2)^2 + (1 - x_i)^2 \\right]$$
                   </div>
                   <p><strong>Global Minimum:</strong> \\(f(\\mathbf{x}^*) = 0\\) at \\(\\mathbf{x}^* = (1, 1, \\ldots, 1)\\)</p>
                   <p><strong>Characteristics:</strong> The global minimum lies inside a long, narrow, parabolic shaped flat valley. Finding the valley is trivial, but converging to the global minimum is difficult.</p>`
        },
        himmelblau: {
            title: "Himmelblau's Function",
            body: `<p>A multi-modal test function used to evaluate optimization algorithms.</p>
                   <div class="formula-box">
                       $$f(x, y) = (x^2 + y - 11)^2 + (x + y^2 - 7)^2$$
                   </div>
                   <p><strong>Global Minima:</strong> Has four identical local minima where \\(f(\\mathbf{x}^*) = 0\\):</p>
                   <ul>
                       <li>\\((3.0, 2.0)\\)</li>
                       <li>\\((-2.805, 3.131)\\)</li>
                       <li>\\((-3.779, -3.283)\\)</li>
                       <li>\\((3.584, -1.848)\\)</li>
                   </ul>`
        },
        sphere: {
            title: "Axis Parallel Hyper-Ellipsoid",
            body: `<p>A strictly convex, generalized formulation of the Sphere function with poor conditioning.</p>
                   <div class="formula-box">
                       $$f(\\mathbf{x}) = \\sum_{i=1}^{n} i \\cdot x_i^2$$
                   </div>
                   <p><strong>Global Minimum:</strong> \\(f(\\mathbf{x}^*) = 0\\) at \\(\\mathbf{x}^* = (0, 0, \\ldots, 0)\\)</p>
                   <p><strong>Characteristics:</strong> Because each dimension is scaled by its index \\(i\\), the level sets are hyperellipsoids rather than hyperspheres. This illustrates the "zig-zag" behavior of the Steepest Descent method.</p>`
        },
        custom: {
            title: "Custom Function Syntax Guide",
            body: `<p>Please use standard programming syntax for mathematical operations. The function is compiled and differentiated dynamically by Julia.</p>
                   <ul>
                       <li><strong>Variables:</strong> <code>x[1], x[2], x[3]...</code></li>
                       <li><strong>Absolute value:</strong> <code>abs(x[1])</code> (DO NOT use |x|)</li>
                       <li><strong>Square root:</strong> <code>sqrt(x[1])</code></li>
                       <li><strong>Powers:</strong> <code>x[1]^2</code></li>
                       <li><strong>Multiplication:</strong> Explicitly use <code>*</code> (e.g., <code>0.01 * x[1]^2</code>)</li>
                       <li><strong>Trigonometry:</strong> <code>sin(), cos(), tan()</code></li>
                       <li><strong>Logarithms:</strong> <code>log()</code> (natural), <code>log10()</code></li>
                   </ul>`
        }
    },
    termination: {
        title: "Termination Criteria",
        body: `<p>Optimization algorithms generally run indefinitely unless a stopping condition is met. You can select one of the following criteria to halt the algorithm when the specified tolerance \\(\\epsilon\\) is reached.</p>
               <ul style="line-height: 1.8;">
                   <li><strong>Gradient Magnitude:</strong> Stops when the norm of the gradient is close to zero (indicating a stationary point).<br>
                   <div class="formula-box" style="padding: 5px; margin: 5px 0;">$$||\\nabla f(x_k)|| < \\epsilon_g$$</div></li>
                   <li><strong>Step Size Tolerance:</strong> Stops when the distance between consecutive iterations becomes negligible.<br>
                   <div class="formula-box" style="padding: 5px; margin: 5px 0;">$$||x_{k+1} - x_k|| < \\epsilon_x$$</div></li>
                   <li><strong>Absolute Improvement:</strong> Stops when the change in the function value over subsequent steps is extremely small.<br>
                   <div class="formula-box" style="padding: 5px; margin: 5px 0;">$$|f(x_k) - f(x_{k+1})| < \\epsilon_a$$</div></li>
                   <li><strong>Relative Improvement:</strong> Stops when the relative change in the function value is extremely small, useful for functions with very large magnitudes.<br>
                   <div class="formula-box" style="padding: 5px; margin: 5px 0;">$$|f(x_k) - f(x_{k+1})| < \\epsilon_r |f(x_k)|$$</div></li>
                   <li><strong>Maximum Iterations:</strong> The algorithm will always stop if the iteration count exceeds \\(k_{max}\\) as a safeguard against infinite loops.</li>
               </ul>`
    }
};

function showInfoModal(type) {
    let data = null;
    if (type === 'function') {
        const func = functionSelect.value;
        data = modalContent.function[func];
    } else if (type === 'termination') {
        data = modalContent.termination;
    }

    if (!data) return;
    document.getElementById('modalTitle').innerText = data.title;
    document.getElementById('modalBody').innerHTML = data.body;
    document.getElementById('infoModal').style.display = "block";
    if (window.MathJax) MathJax.typesetPromise([document.getElementById('infoModal')]).catch(err => console.log(err));
}

function closeModal() { document.getElementById('infoModal').style.display = "none"; }
window.onclick = function(event) { if (event.target == document.getElementById('infoModal')) closeModal(); }

function juliaToLatex(str) {
    let tex = str.replace(/x\[(\d+)\]/g, 'x_{$1}').replace(/\*/g, '\\cdot').replace(/\^/g, '^');
    tex = tex.replace(/abs\(([^)]+)\)/g, '|$1|');
    tex = tex.replace(/\b(sin|cos|tan|exp|log|ln|sqrt)\b/g, '\\$1');
    return `$$ f(\\mathbf{x}) = ${tex} $$`;
}

function closePreview() {
    document.getElementById('previewModal').style.display = 'none';
}

document.getElementById('runBtn').addEventListener('click', () => {
    const func = functionSelect.value;
    if (func === 'custom') {
        const formula = document.getElementById('customFormula').value;
        if (!formula.trim()) {
            alert("Please enter a formula for the custom function.");
            return;
        }
        document.getElementById('latexPreview').innerHTML = juliaToLatex(formula);
        document.getElementById('previewModal').style.display = 'block';
        if (window.MathJax) MathJax.typesetPromise([document.getElementById('previewModal')]).catch(err => console.log(err));
    } else {
        runOptimization();
    }
});

async function startOptimization() {
    closePreview();
    runOptimization();
}

async function runOptimization() {
    const func = functionSelect.value;
    const method = methodSelect.value;
    const ls = lsSelect.value;
    
    const N = func === 'himmelblau' ? 2 : parseInt(dimInput.value);
    let x0_arr = [];
    for(let i=1; i<=N; i++) {
        const el = document.getElementById(`x0_${i}`);
        if (!el) {
            alert("Starting points not fully initialized. Please wait a second.");
            return;
        }
        x0_arr.push(el.value);
    }
    const x0_str = x0_arr.join(",");
    
    const dim_x = axisX.value;
    const dim_y = axisY.value;

    const termCriterion = document.getElementById('termSelect').value;
    const tolVal = document.getElementById('tolInput').value;
    const maxIterVal = document.getElementById('maxIterInput').value;

    let mValue = 5;
    if (method === 'lbfgs') {
        const parsedM = Number(document.getElementById('mInput').value);
        if (isNaN(parsedM) || !Number.isInteger(parsedM) || parsedM < 1) {
            alert("Error: Memory size (m) must be a positive integer.");
            return; 
        }
        mValue = parsedM;
    }

    let methodLabel = methodSelect.options[methodSelect.selectedIndex].text;
    if (method === 'cg') methodLabel = document.getElementById('cgVariantSelect').options[document.getElementById('cgVariantSelect').selectedIndex].text;
    else if (method === 'lbfgs') methodLabel = `L-BFGS (m=${mValue})`;
    
    let customFormula = '';
    if (func === 'custom') {
        customFormula = document.getElementById('customFormula').value;
    }
    
    const url = `http://127.0.0.1:8080/optimize?function=${func}&custom_formula=${encodeURIComponent(customFormula)}&method=${method}&cg_variant=${document.getElementById('cgVariantSelect').value}&m=${mValue}&linesearch=${ls}&auto_bracket=${document.getElementById('autoBracketCb').checked}&bracket_a=${document.getElementById('bracketA').value}&bracket_b=${document.getElementById('bracketB').value}&x0=${x0_str}&dim_x=${dim_x}&dim_y=${dim_y}&term_criterion=${termCriterion}&tol=${tolVal}&max_iter=${maxIterVal}`;
    
    document.getElementById('loadingOverlay').classList.add('active');
    
    try {
        const response = await fetch(url);
        const data = await response.json();
        
        document.getElementById('loadingOverlay').classList.remove('active');
        
        if (data.status === 'error') {
            alert("Error: " + data.message);
            return;
        }
        
        if (data.status !== "success" && !data.diverged) return alert("Optimization failed.");

        const contourTrace = {
            z: data.contour_z,
            x: data.contour_x,
            y: data.contour_y,
            type: 'contour',
            colorscale: 'YlGnBu',
            ncontours: 40,
            line: { smoothing: 1.3, color: 'rgba(0,0,0,0.3)', width: 0.8 },
            contours: { coloring: 'heatmap' },
            name: 'Contours'
        };

        const hoverTexts = data.full_x_hist.map((pt, i) => {
            let txt = `<b>Iteration:</b> ${i}<br>`;
            const fval = data.f_hist[i];
            txt += `<b>f(x):</b> ${fval !== null ? fval.toExponential(4) : 'NaN'}<br>`;
            pt.forEach((val, dim) => {
                const vStr = val !== null ? val.toFixed(4) : 'NaN';
                txt += `<b>x<sub>${dim+1}</sub>:</b> ${vStr}<br>`;
            });
            return txt;
        });

        const trajectoryTrace = {
            x: data.x_hist, 
            y: data.y_hist, 
            mode: 'lines+markers', 
            type: 'scatter',
            line: { color: 'red', width: 2.5 }, 
            marker: { color: 'red', size: 5 }, 
            name: methodLabel,
            text: hoverTexts,
            hovertemplate: '%{text}<extra></extra>' 
        };

        const layout = {
            title: `${functionSelect.options[functionSelect.selectedIndex].text} Slice (x${dim_x}, x${dim_y})`,
            xaxis: { title: `x${dim_x}`, layer: 'above traces' },
            yaxis: { title: `x${dim_y}`, layer: 'above traces' }
        };

        if (document.getElementById('equalAxesCb').checked) {
            layout.yaxis.scaleanchor = 'x';
            layout.yaxis.scaleratio = 1;
        }

        Plotly.newPlot('plotDiv', [contourTrace, trajectoryTrace], layout);
        attachRelayoutListener();

        document.getElementById('resultsPanel').classList.remove('hidden');
        document.getElementById('iterCount').innerText = data.iterations;

        const warnBox = document.getElementById('divergenceWarning');
        const divDetails = document.getElementById('divergenceDetails');
        if (data.diverged) {
            warnBox.classList.remove('hidden');
            
            const gradStr = data.final_grad_norm !== null ? data.final_grad_norm.toExponential(3) : 'NaN';
            const fStr = data.final_f_value !== null ? data.final_f_value.toExponential(3) : 'NaN';

            divDetails.innerHTML = `
                <div><strong>Reason:</strong> ${data.divergence_reason}</div>
                <div><strong>Iteration:</strong> ${data.divergence_iteration}/${maxIterVal}</div>
                <div><strong>Final Gradient Norm:</strong> ||∇f(x)|| = ${gradStr}</div>
                <div><strong>Final Function Value:</strong> f(x) = ${fStr}</div>
            `;
        } else {
            warnBox.classList.add('hidden');
        }

        const itArr = Array.from({length: data.iterations + 1}, (_, i) => i);
        const alphaArrAligned = [0, ...data.alpha_hist]; 
        const logType = document.getElementById('logScaleCb').checked ? 'log' : 'linear';

        Plotly.newPlot('fPlotDiv', [{ x: itArr, y: data.f_hist, mode: 'lines+markers', type: 'scatter', line: { color: 'blue' }, name: 'f(x)' }], 
            { margin: { t: 20, b: 40, l: 50, r: 20 }, xaxis: { title: 'Iteration (k)' }, yaxis: { title: 'f(x)', type: logType } });

        Plotly.newPlot('gradPlotDiv', [{ x: itArr, y: data.grad_norm_hist, mode: 'lines+markers', type: 'scatter', line: { color: 'green' }, name: '||∇f(x)||' }], 
            { margin: { t: 20, b: 40, l: 50, r: 20 }, xaxis: { title: 'Iteration (k)' }, yaxis: { title: '||∇f(x)||', type: logType } });

        Plotly.newPlot('alphaPlotDiv', [{ x: itArr, y: alphaArrAligned, mode: 'lines+markers', type: 'scatter', line: { color: 'purple' }, name: 'α (step size)' }], 
            { margin: { t: 20, b: 40, l: 50, r: 20 }, xaxis: { title: 'Iteration (k)' }, yaxis: { title: 'Step Size (α)', type: logType } });
        
    } catch (error) {
        document.getElementById('loadingOverlay').classList.remove('active');
        alert("Backend error: " + error.message);
    }
}