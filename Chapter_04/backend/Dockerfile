# official Julia Docker image with version 1.10
FROM julia:1.10

# Set the working directory in the container
WORKDIR /app

# Copy the Project.toml and Manifest.toml files to the container
COPY Project.toml Manifest.toml ./

# Install the dependencies and precompile them
RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate(); Pkg.precompile()'

# Copy the rest of the application code to the container
COPY . .

# Expose the port that the server will run on
EXPOSE 8080

# Run the server when the container starts
CMD ["julia", "--project", "server.jl"]