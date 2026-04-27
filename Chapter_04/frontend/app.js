// app.js

const functionSelect = document.getElementById('functionSelect');
const dimInput = document.getElementById('dimInput');
const x0Inputs = document.getElementById('x0Inputs');
const axisX = document.getElementById('axisX');
const axisY = document.getElementById('axisY');
const plotDiv = document.getElementById('plotDiv');
const API_BASE_URL = "https://optimization-app-wkcn.onrender.com"; // backend server url
let debounceTimer;

// --- CHYTRÝ LOADER PRO DETEKCI COLD-STARTU ---
let coldStartTimer;

function showLoading(baseText) {
    const loadingOverlay = document.getElementById('loadingOverlay');
    const loadingText = document.getElementById('loadingText');
    
    loadingText.innerHTML = baseText;
    loadingOverlay.classList.add('active');
    
    clearTimeout(coldStartTimer);
    // Pokud server neodpoví do 3.5 vteřin, předpokládáme, že spí a probouzí se
    coldStartTimer = setTimeout(() => {
        loadingText.innerHTML = `${baseText}<br><br>
            <span style="font-size: 14px; color: #005A9E; font-weight: normal; max-width: 400px; display: inline-block; margin-top: 10px; line-height: 1.4;">
                ☕ <b>Waking up the server...</b><br>
                Since this is hosted on a free tier, the backend goes to sleep after inactivity. 
                This initial start may take <b>30 to 60 seconds</b>. Subsequent requests will be instant!
            </span>`;
    }, 3500);
}

function hideLoading() {
    clearTimeout(coldStartTimer);
    document.getElementById('loadingOverlay').classList.remove('active');
}
// ---------------------------------------------

// Globální konfigurace pro SVG export
const getSvgConfig = (fileName) => ({
    toImageButtonOptions: {
        format: 'svg',
        filename: fileName
    },
    responsive: true
});

document.addEventListener('DOMContentLoaded', () => {
    updateDimensions();
});

function updateDimensions() {
    const func = functionSelect.value;
    let N = parseInt(dimInput.value);
    
    const only2D = ['himmelblau', 'beale', 'booth', 'goldstein_price', 'matyas', 'levi_n13', 'three_hump_camel'];
    
    if (only2D.includes(func)) {
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
        else if (func === 'ackley') val = 3.0;
        else if (func === 'himmelblau' && i === 1) val = -0.27;
        else if (func === 'himmelblau' && i === 2) val = -0.9;
        else if (func === 'beale') val = -1.0;
        else if (func === 'booth') val = 4.0;
        else if (func === 'goldstein_price' && i === 1) val = 0.5;
        else if (func === 'goldstein_price' && i === 2) val = -0.5;
        else if (func === 'matyas') val = 5.0;
        else if (func === 'levi_n13') val = 3.0;
        else if (func === 'three_hump_camel') val = 2.0;
        else if (func === 'sphere') { val = (i % 2 === 0) ? 3.0 : -4.0; } 

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
    if (document.getElementById('distPlotDiv').data) Plotly.relayout('distPlotDiv', {'yaxis.type': type});
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
            } catch(e) {}
        }, 400); 
    });
}

async function fetchNewContours(xmin, xmax, ymin, ymax) {
    showLoading("Recalculating View...");

    const func = functionSelect.value;
    const N = func === 'himmelblau' ? 2 : parseInt(dimInput.value);
    let x0_arr = [];
    for(let i=1; i<=N; i++) {
        const el = document.getElementById(`x0_${i}`);
        x0_arr.push(el ? el.value : "0.0");
    }
    const x0_str = x0_arr.join(",");
    const customFormula = func === 'custom' ? document.getElementById('customFormula').value : "";

    const url = `${API_BASE_URL}/contours?function=${func}&custom_formula=${encodeURIComponent(customFormula)}&xmin=${xmin}&xmax=${xmax}&ymin=${ymin}&ymax=${ymax}&dim_x=${axisX.value}&dim_y=${axisY.value}&x0=${x0_str}`;
    
    try {
        const res = await fetch(url);
        const data = await res.json();
        
        if (data.contour_z && plotDiv.data && plotDiv.data.length > 0) {
            plotDiv.data[0].x = data.contour_x;
            plotDiv.data[0].y = data.contour_y;
            plotDiv.data[0].z = data.contour_z;
            Plotly.redraw(plotDiv);
        }
    } catch (error) {} finally {
        hideLoading();
    }
}

async function drawInitialPlot() {
    const func = functionSelect.value;
    if (func === 'custom' && !document.getElementById('customFormula').value.trim()) {
        Plotly.newPlot('plotDiv', [], {title: "Awaiting custom formula..."}, getSvgConfig('empty_plot'));
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

    showLoading("Initializing Function Topology...");

    const url = `${API_BASE_URL}/contours?function=${func}&custom_formula=${encodeURIComponent(customFormula)}&xmin=${xmin}&xmax=${xmax}&ymin=${ymin}&ymax=${ymax}&dim_x=${axisX.value}&dim_y=${axisY.value}&x0=${x0_str}`;
    
    try {
        const res = await fetch(url);
        const data = await res.json();
        
        if(data.error || !data.contour_z) {
            Plotly.newPlot('plotDiv', [], {title: "Function definition invalid or incomplete."}, getSvgConfig('invalid_plot'));
            hideLoading();
            return;
        }

        const contourTrace = {
            z: data.contour_z, x: data.contour_x, y: data.contour_y,
            type: 'contour', colorscale: 'Spectral', ncontours: 40,
            line: { smoothing: 1.3, color: 'rgba(0,0,0,0.3)', width: 0.8 },
            contours: { coloring: 'heatmap' }, name: 'Contours'
        };

        const layout = {
            title: `${functionSelect.options[functionSelect.selectedIndex].text} Slice (x${axisX.value}, x${axisY.value})`,
            xaxis: { title: `x${axisX.value}`, range: [xmin, xmax] },
            yaxis: { title: `x${axisY.value}`, range: [ymin, ymax] },
            dragmode: 'zoom'
        };

        Plotly.newPlot('plotDiv', [contourTrace], layout, getSvgConfig('initial_contour_plot'));
        attachRelayoutListener();
    } catch(e) {} finally {
        hideLoading();
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

function enlargePlot(divId, title) {
    document.getElementById('plotEnlargeTitle').innerText = title;
    document.getElementById('plotEnlargeModal').style.display = 'block';
    
    const sourceData = document.getElementById(divId).data;
    const sourceLayout = document.getElementById(divId).layout;
    
    const layoutCopy = JSON.parse(JSON.stringify(sourceLayout));
    layoutCopy.margin = {t: 20, b: 60, l: 80, r: 20};
    
    // Přidáno getSvgConfig pro zvětšené okno
    Plotly.newPlot('enlargedPlotDiv', sourceData, layoutCopy, getSvgConfig(`enlarged_${title.replace(/[^a-zA-Z0-9]/g, '_').toLowerCase()}`));
    window.addEventListener('resize', resizeEnlargedPlot);
}

function resizeEnlargedPlot() {
    Plotly.Plots.resize('enlargedPlotDiv');
}

function closePlotModal() {
    document.getElementById('plotEnlargeModal').style.display = 'none';
    window.removeEventListener('resize', resizeEnlargedPlot);
    Plotly.purge('enlargedPlotDiv'); 
}

const modalContent = {
    function: {
        rosenbrock: { title: "Rosenbrock Function", body: `<p>A popular multimodal test problem characterized by a long, narrow, parabolic shaped flat valley.</p><div class="formula-box">$$f(\\mathbf{x}) = \\sum_{i=1}^{n-1} \\left[ 100(x_{i+1} - x_i^2)^2 + (1 - x_i)^2 \\right]$$</div><p><strong>Global Minimum:</strong> \\(f(\\mathbf{x}^*) = 0\\) at \\(\\mathbf{x}^* = (1, \\dots, 1)\\)</p><p><strong>Source:</strong> <a href="https://www.sfu.ca/~ssurjano/rosen.html" target="_blank">SFU Library</a></p>` },
        ackley: { title: "Ackley Function", body: `<p>Characterized by a nearly flat outer region, and a large hole at the center. Poses a high risk for hill-climbing algorithms to be trapped in local minima.</p><div class="formula-box">$$f(\\mathbf{x}) = -20 \\exp\\left(-0.2 \\sqrt{\\frac{1}{d}\\sum_{i=1}^d x_i^2}\\right) - \\exp\\left(\\frac{1}{d}\\sum_{i=1}^d \\cos(2\\pi x_i)\\right) + 20 + e$$</div><p><strong>Global Minimum:</strong> \\(f(\\mathbf{x}^*) = 0\\) at \\(\\mathbf{x}^* = (0, \\dots, 0)\\)</p><p><strong>Source:</strong> <a href="https://www.sfu.ca/~ssurjano/ackley.html" target="_blank">SFU Library</a></p>` },
        sphere: { title: "Axis Parallel Hyper-Ellipsoid", body: `<p>A strictly convex, generalized formulation of the Sphere function with poor conditioning.</p><div class="formula-box">$$f(\\mathbf{x}) = \\sum_{i=1}^{n} i \\cdot x_i^2$$</div><p><strong>Global Minimum:</strong> \\(f(\\mathbf{x}^*) = 0\\) at \\(\\mathbf{x}^* = (0, \\dots, 0)\\)</p><p><strong>Source:</strong> <a href="https://www.sfu.ca/~ssurjano/sumsqu.html" target="_blank">SFU Library</a></p>` },
        himmelblau: { title: "Himmelblau's Function", body: `<p>A multi-modal test function used to evaluate optimization algorithms.</p><div class="formula-box">$$f(x, y) = (x^2 + y - 11)^2 + (x + y^2 - 7)^2$$</div><p><strong>Global Minima:</strong> Has four identical local minima where \\(f(\\mathbf{x}^*) = 0\\):</p><ul><li>\\((3.0, 2.0)\\)</li><li>\\((-2.805, 3.131)\\)</li><li>\\((-3.779, -3.283)\\)</li><li>\\((3.584, -1.848)\\)</li></ul><p><strong>Source:</strong> <a href="https://en.wikipedia.org/wiki/Himmelblau%27s_function" target="_blank">Wikipedia</a></p>` },
        beale: { title: "Beale Function", body: `<p>Multimodal, with sharp peaks at the corners of the input domain and very flat valleys.</p><div class="formula-box">$$f(x,y) = (1.5 - x + xy)^2 + (2.25 - x + xy^2)^2 + (2.625 - x + xy^3)^2$$</div><p><strong>Global Minimum:</strong> \\(f(\\mathbf{x}^*) = 0\\) at \\(\\mathbf{x}^* = (3, 0.5)\\)</p><p><strong>Source:</strong> <a href="https://www.sfu.ca/~ssurjano/beale.html" target="_blank">SFU Library</a></p>` },
        booth: { title: "Booth Function", body: `<p>A valley-shaped function. Good for testing pure gradient methods versus Newtonian ones.</p><div class="formula-box">$$f(x,y) = (x + 2y - 7)^2 + (2x + y - 5)^2$$</div><p><strong>Global Minimum:</strong> \\(f(\\mathbf{x}^*) = 0\\) at \\(\\mathbf{x}^* = (1, 3)\\)</p><p><strong>Source:</strong> <a href="https://www.sfu.ca/~ssurjano/booth.html" target="_blank">SFU Library</a></p>` },
        goldstein_price: { title: "Goldstein-Price Function", body: `<p>Polynomial with several local minima.</p><div class="formula-box">$$f(x,y) = \\left[1 + (x+y+1)^2(19-14x+3x^2-14y+6xy+3y^2)\\right] \\\\ \\times \\left[30 + (2x-3y)^2(18-32x+12x^2+48y-36xy+27y^2)\\right]$$</div><p><strong>Global Minimum:</strong> \\(f(\\mathbf{x}^*) = 3\\) at \\(\\mathbf{x}^* = (0, -1)\\)</p><p><strong>Source:</strong> <a href="https://www.sfu.ca/~ssurjano/goldpr.html" target="_blank">SFU Library</a></p>` },
        matyas: { title: "Matyas Function", body: `<p>A plate-shaped function with no local minima except the global one.</p><div class="formula-box">$$f(x,y) = 0.26(x^2 + y^2) - 0.48xy$$</div><p><strong>Global Minimum:</strong> \\(f(\\mathbf{x}^*) = 0\\) at \\(\\mathbf{x}^* = (0, 0)\\)</p><p><strong>Source:</strong> <a href="https://www.sfu.ca/~ssurjano/matya.html" target="_blank">SFU Library</a></p>` },
        levi_n13: { title: "Lévi Function N.13", body: `<p>A highly multimodal function due to the trigonometric components.</p><div class="formula-box">$$f(x,y) = \\sin^2(3\\pi x) + (x-1)^2[1 + \\sin^2(3\\pi y)] + (y-1)^2[1 + \\sin^2(2\\pi y)]$$</div><p><strong>Global Minimum:</strong> \\(f(\\mathbf{x}^*) = 0\\) at \\(\\mathbf{x}^* = (1, 1)\\)</p><p><strong>Source:</strong> <a href="https://www.sfu.ca/~ssurjano/levy13.html" target="_blank">SFU Library</a></p>` },
        three_hump_camel: { title: "Three-Hump Camel Function", body: `<p>Features exactly three local minima, one of which is the global minimum.</p><div class="formula-box">$$f(x,y) = 2x^2 - 1.05x^4 + \\frac{x^6}{6} + xy + y^2$$</div><p><strong>Global Minimum:</strong> \\(f(\\mathbf{x}^*) = 0\\) at \\(\\mathbf{x}^* = (0, 0)\\)</p><p><strong>Source:</strong> <a href="https://www.sfu.ca/~ssurjano/camel3.html" target="_blank">SFU Library</a></p>` },
        custom: { title: "Custom Function Syntax Guide", body: `<p>Please use standard programming syntax for mathematical operations. The function is compiled and differentiated dynamically by Julia.</p><ul><li><strong>Variables:</strong> <code>x[1], x[2], x[3]...</code></li><li><strong>Absolute value:</strong> <code>abs(x[1])</code> (DO NOT use |x|)</li><li><strong>Square root:</strong> <code>sqrt(x[1])</code></li><li><strong>Powers:</strong> <code>x[1]^2</code></li><li><strong>Multiplication:</strong> Explicitly use <code>*</code> (e.g., <code>0.01 * x[1]^2</code>)</li><li><strong>Trigonometry:</strong> <code>sin(), cos(), tan()</code></li><li><strong>Logarithms:</strong> <code>log()</code> (natural), <code>log10()</code></li></ul>` }
    },
    termination: { title: "Termination Criteria", body: `<p>Optimization algorithms generally run indefinitely unless a stopping condition is met. You can select one of the following criteria to halt the algorithm when the specified tolerance \\(\\epsilon\\) is reached.</p><ul style="line-height: 1.8;"><li><strong>Gradient Magnitude:</strong> Stops when the norm of the gradient is close to zero (indicating a stationary point).<br><div class="formula-box" style="padding: 5px; margin: 5px 0;">$$||\\nabla f(x_k)|| < \\epsilon_g$$</div></li><li><strong>Step Size Tolerance:</strong> Stops when the distance between consecutive iterations becomes negligible.<br><div class="formula-box" style="padding: 5px; margin: 5px 0;">$$||x_{k+1} - x_k|| < \\epsilon_x$$</div></li><li><strong>Absolute Improvement:</strong> Stops when the change in the function value over subsequent steps is extremely small.<br><div class="formula-box" style="padding: 5px; margin: 5px 0;">$$|f(x_k) - f(x_{k+1})| < \\epsilon_a$$</div></li><li><strong>Relative Improvement:</strong> Stops when the relative change in the function value is extremely small, useful for functions with very large magnitudes.<br><div class="formula-box" style="padding: 5px; margin: 5px 0;">$$|f(x_k) - f(x_{k+1})| < \\epsilon_r |f(x_k)|$$</div></li><li><strong>Maximum Iterations:</strong> The algorithm will always stop if the iteration count exceeds \\(k_{max}\\) as a safeguard against infinite loops.</li></ul>` }
};

function showInfoModal(type) {
    let data = null;
    if (type === 'function') data = modalContent.function[functionSelect.value];
    else if (type === 'termination') data = modalContent.termination;

    if (!data) return;
    document.getElementById('modalTitle').innerText = data.title;
    document.getElementById('modalBody').innerHTML = data.body;
    document.getElementById('infoModal').style.display = "block";
    if (window.MathJax) MathJax.typesetPromise([document.getElementById('infoModal')]).catch(e => console.log(e));
}

function closeModal() { document.getElementById('infoModal').style.display = "none"; }
window.onclick = function(event) { 
    if (event.target == document.getElementById('infoModal')) closeModal(); 
    if (event.target == document.getElementById('plotEnlargeModal')) closePlotModal();
}

function juliaToLatex(str) {
    let tex = str.replace(/x\[(\d+)\]/g, 'x_{$1}').replace(/\*/g, '\\cdot').replace(/\^/g, '^');
    tex = tex.replace(/abs\(([^)]+)\)/g, '|$1|');
    tex = tex.replace(/\b(sin|cos|tan|exp|log|ln|sqrt)\b/g, '\\$1');
    return `$$ f(\\mathbf{x}) = ${tex} $$`;
}

function closePreview() { document.getElementById('previewModal').style.display = 'none'; }

document.getElementById('runBtn').addEventListener('click', () => {
    const func = functionSelect.value;
    if (func === 'custom') {
        const formula = document.getElementById('customFormula').value;
        if (!formula.trim()) return alert("Please enter a formula for the custom function.");
        document.getElementById('latexPreview').innerHTML = juliaToLatex(formula);
        document.getElementById('previewModal').style.display = 'block';
        if (window.MathJax) MathJax.typesetPromise([document.getElementById('previewModal')]).catch(e => console.log(e));
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
        if (!el) return alert("Starting points not fully initialized. Please wait a second.");
        x0_arr.push(el.value);
    }
    
    const termCriterion = document.getElementById('termSelect').value;
    const tolVal = document.getElementById('tolInput').value;
    const maxIterVal = document.getElementById('maxIterInput').value;

    let mValue = 5;
    if (method === 'lbfgs') {
        mValue = Number(document.getElementById('mInput').value);
        if (isNaN(mValue) || !Number.isInteger(mValue) || mValue < 1) return alert("Error: Memory size (m) must be a positive integer.");
    }

    let methodLabel = methodSelect.options[methodSelect.selectedIndex].text;
    if (method === 'cg') methodLabel = document.getElementById('cgVariantSelect').options[document.getElementById('cgVariantSelect').selectedIndex].text;
    else if (method === 'lbfgs') methodLabel = `L-BFGS (m=${mValue})`;
    
    const customFormula = func === 'custom' ? document.getElementById('customFormula').value : '';
    const url = `${API_BASE_URL}/optimize?function=${func}&custom_formula=${encodeURIComponent(customFormula)}&method=${method}&cg_variant=${document.getElementById('cgVariantSelect').value}&m=${mValue}&linesearch=${ls}&auto_bracket=${document.getElementById('autoBracketCb').checked}&bracket_a=${document.getElementById('bracketA').value}&bracket_b=${document.getElementById('bracketB').value}&x0=${x0_arr.join(',')}&dim_x=${axisX.value}&dim_y=${axisY.value}&term_criterion=${termCriterion}&tol=${tolVal}&max_iter=${maxIterVal}`;
    
    showLoading("Optimizing... Please Wait");
    
    try {
        const response = await fetch(url);
        const data = await response.json();
        
        hideLoading();

        if (data.status === 'error') return alert("Error: " + data.message);
        if (data.status !== "success" && !data.diverged) return alert("Optimization failed.");

        const contourTrace = {
            z: data.contour_z, x: data.contour_x, y: data.contour_y,
            type: 'contour', colorscale: 'Spectral', ncontours: 40,
            line: { smoothing: 1.3, color: 'rgba(0,0,0,0.3)', width: 0.8 },
            contours: { coloring: 'heatmap' }, name: 'Contours', hoverinfo: 'skip'
        };

        const hoverTexts = data.full_x_hist.map((pt, i) => {
            let txt = `<b>Iteration:</b> ${i}<br>`;
            const fval = data.f_hist[i];
            txt += `<b>f(x):</b> ${fval !== null ? fval.toExponential(4) : 'NaN'}<br>`;
            pt.forEach((val, dim) => txt += `<b>x<sub>${dim+1}</sub>:</b> ${val !== null ? val.toFixed(4) : 'NaN'}<br>`);
            return txt;
        });

        let traces = [contourTrace];

        traces.push({
            x: data.x_hist, y: data.y_hist, 
            mode: 'lines', line: { color: '#dc3545', width: 2.5 }, 
            name: 'Trajectory', hoverinfo: 'skip'
        });

        traces.push({
            x: [data.x_hist[0]], y: [data.y_hist[0]], 
            mode: 'markers', marker: { color: '#28a745', size: 10, symbol: 'square', line: {color:'white', width:1} }, 
            name: 'Start Point', text: [hoverTexts[0]], hovertemplate: '%{text}<extra></extra>'
        });

        const isSuccess = data.status === 'success' && !data.diverged;
        const endIdx = isSuccess ? data.x_hist.length - 1 : data.x_hist.length;
        if (endIdx > 1) {
            traces.push({
                x: data.x_hist.slice(1, endIdx), y: data.y_hist.slice(1, endIdx), 
                mode: 'markers', marker: { color: '#005A9E', size: 8, line: {color:'white', width:1} }, 
                name: 'Intermediates', text: hoverTexts.slice(1, endIdx), hovertemplate: '%{text}<extra></extra>'
            });
        }

        if (isSuccess) {
            const lastIdx = data.x_hist.length - 1;
            traces.push({
                x: [data.x_hist[lastIdx]], y: [data.y_hist[lastIdx]], 
                mode: 'markers', marker: { color: '#ffc107', size: 16, symbol: 'star', line: {color:'black', width:1} }, 
                name: 'Converged Minimum', text: [hoverTexts[lastIdx]], hovertemplate: '%{text}<extra></extra>'
            });
        }

        if (data.true_min_full !== null) {
            let gtHover = `<b>Ground Truth (Optim.jl)</b><br>f(x): ${data.true_min_f.toExponential(4)}<br>`;
            data.true_min_full.forEach((v, i) => {
                gtHover += `x<sub>${i+1}</sub>: ${v.toFixed(4)}<br>`;
            });

            traces.push({
                x: [data.true_min_full[axisX.value-1]],
                y: [data.true_min_full[axisY.value-1]],
                mode: 'markers',
                marker: { color: '#000', size: 14, symbol: 'x-thin', line: {width:3} },
                name: 'Ground Truth',
                text: [gtHover],
                hovertemplate: '%{text}<extra></extra>'
            });
        }

        const layout = {
            title: `${functionSelect.options[functionSelect.selectedIndex].text} Slice (x${axisX.value}, x${axisY.value})`,
            xaxis: { title: `x${axisX.value}`, layer: 'above traces' },
            yaxis: { title: `x${axisY.value}`, layer: 'above traces' },
            legend: { orientation: 'h', y: -0.15 },
            dragmode: 'zoom'
        };

        if (document.getElementById('equalAxesCb').checked) {
            layout.yaxis.scaleanchor = 'x';
            layout.yaxis.scaleratio = 1;
        }

        Plotly.newPlot('plotDiv', traces, layout, getSvgConfig('optimization_trajectory'));
        attachRelayoutListener();

        document.getElementById('resultsPanel').classList.remove('hidden');
        document.getElementById('iterCount').innerText = data.iterations;

        const warnBox = document.getElementById('divergenceWarning');
        if (data.diverged) {
            warnBox.classList.remove('hidden');
            const gradStr = data.final_grad_norm !== null ? data.final_grad_norm.toExponential(3) : 'NaN';
            const fStr = data.final_f_value !== null ? data.final_f_value.toExponential(3) : 'NaN';
            document.getElementById('divergenceDetails').innerHTML = `
                <div><strong>Reason:</strong> ${data.divergence_reason}</div>
                <div><strong>Iteration:</strong> ${data.divergence_iteration}/${maxIterVal}</div>
                <div><strong>Final Gradient Norm:</strong> ||∇f(x)|| = ${gradStr}</div>
                <div><strong>Final Function Value:</strong> f(x) = ${fStr}</div>`;
        } else {
            warnBox.classList.add('hidden');
        }

        const logType = document.getElementById('logScaleCb').checked ? 'log' : 'linear';
        
        const commonLayout = {
            margin: { t: 30, b: 50, l: 80, r: 20 },
            xaxis: { title: { text: 'Iteration (k)' } },
            yaxis: { type: logType, exponentformat: 'power' },
            hovermode: 'closest',
            dragmode: 'zoom'
        };

        const itArr = Array.from({length: data.iterations + 1}, (_, i) => i);
        
        Plotly.newPlot('fPlotDiv', [{ 
            x: itArr, y: data.f_hist, mode: 'lines+markers', type: 'scatter', line: { color: 'blue' },
            hovertemplate: 'Iteration (k): %{x}<br>Value: %{y:.4e}<extra></extra>' 
        }], { ...commonLayout, yaxis: { ...commonLayout.yaxis, title: { text: '<i>f(x<sub>k</sub>)</i>' } } }, getSvgConfig('f_x_evolution'));

        Plotly.newPlot('gradPlotDiv', [{ 
            x: itArr, y: data.grad_norm_hist, mode: 'lines+markers', type: 'scatter', line: { color: 'green' },
            hovertemplate: 'Iteration (k): %{x}<br>||∇f||: %{y:.4e}<extra></extra>' 
        }], { ...commonLayout, yaxis: { ...commonLayout.yaxis, title: { text: '||∇<i>f(x<sub>k</sub>)</i>||' } } }, getSvgConfig('gradient_norm_evolution'));

        const alphaArrAligned = [0, ...data.alpha_hist];
        Plotly.newPlot('alphaPlotDiv', [{ 
            x: itArr, y: alphaArrAligned, mode: 'lines+markers', type: 'scatter', line: { color: 'purple' },
            hovertemplate: 'Iteration (k): %{x}<br>α: %{y:.4e}<extra></extra>' 
        }], { ...commonLayout, yaxis: { ...commonLayout.yaxis, title: { text: '<i>α<sub>k</sub></i>' } } }, getSvgConfig('step_size_evolution'));

        const distItArr = Array.from({length: data.iterations}, (_, i) => i);
        Plotly.newPlot('distPlotDiv', [{ 
            x: distItArr, y: data.step_dist_hist, mode: 'lines+markers', type: 'scatter', line: { color: '#ff7f0e' },
            hovertemplate: 'Iteration (k): %{x}<br>Distance: %{y:.4e}<extra></extra>' 
        }], { ...commonLayout, yaxis: { ...commonLayout.yaxis, title: { text: '||<i>x<sub>k+1</sub> - x<sub>k</sub></i>||' } } }, getSvgConfig('step_distance_evolution'));
        
    } catch (error) {
        hideLoading();
    }
}