using Swirl
using ModernGL, GLFW
using Statistics
using LinearAlgebra

include("../common/rendering.jl")


const Nx = 400
const Ny = 200
const N = Nx*Ny
const L = Float64[20, 10]

const CirclePos = Float64[3,5]

function main()

    fluid = let
        T = Float64
        l = L[:]
        n = (Nx, Ny)
        Dx = @. l / (n-1)
        
        v = zeros(T, 2, n[1], n[2])
        p = zeros(T, n)
        d = zeros(T, n)
        coll = ones(T, n)
        
        v[1, :, :] .= 4.0
        
        for i = 1:Nx
            for j = 1:Ny
                x = (i-1) * Dx[1]
                y = (j-1) * Dx[2]
                r = hypot(x-CirclePos[1], y-CirclePos[2])
                if r <= 1.3
                    d[i, j] = 1
                end
                if r <= 1
                    coll[i, j] = -1
                    d[i, j] = 0
                    v[1, i, j] = 0
                end
                if i == 1 || i == Nx || j == 1 || j == Ny
                    coll[i, j] = -1
                else
                    Rscale = 0.1
                    @. v[:, i, j] += rand(T) * 2Rscale - Rscale
                end
            end
        end
            
            
        Swirl.Fluid(Dx, v, coll, p, d)
    end

    window = renderInit("Karman Vortex Street")

    planeData = collect(transpose([
        -1.0f0 -1.0f0 0.0f0 0.0f0
        1.0f0 -1.0f0  1.0f0 0.0f0
        -1.0f0 1.0f0  0.0f0 1.0f0
        1.0f0 -1.0f0  1.0f0 0.0f0
        1.0f0 1.0f0   1.0f0 1.0f0
        -1.0f0 1.0f0  0.0f0 1.0f0
    ]))

    circleData = collect(transpose([
        -1.0f0 -1.0f0 0.0f0 0.0f0
        1.0f0 -1.0f0  1.0f0 0.0f0
        -1.0f0 1.0f0  0.0f0 1.0f0
        1.0f0 -1.0f0  1.0f0 0.0f0
        1.0f0 1.0f0   1.0f0 1.0f0
        -1.0f0 1.0f0  0.0f0 1.0f0
    ]))
    
    for i = 1:6
        for j = 1:2
            planeData[j, i] *= 0.5L[j]
            circleData[j, i] *= 1.2
            circleData[j, i] += CirclePos[j] - 0.5L[j]
        end
    end

    viewScale = Float32[1, 1]

    zoom = 1
    zoomRate = 1.0


    vaos = UInt32[0, 0]
    vbos = UInt32[0, 0]

    ModernGL.glGenVertexArrays(length(vaos), Ref(vaos, 1))
    ModernGL.glGenBuffers(length(vbos), Ref(vbos, 1))

    glBindVertexArray(vaos[1])
    glBindBuffer(GL_ARRAY_BUFFER, vbos[1])
    glBufferData(GL_ARRAY_BUFFER, length(planeData) * sizeof(Float32), planeData, GL_STATIC_DRAW)
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(Float32), Ptr{Cvoid}(0))
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(Float32), Ptr{Cvoid}(2*sizeof(Float32)))
    glEnableVertexAttribArray(0)
    glEnableVertexAttribArray(1)


    glBindVertexArray(vaos[2])
    glBindBuffer(GL_ARRAY_BUFFER, vbos[2])
    glBufferData(GL_ARRAY_BUFFER, length(circleData) * sizeof(Float32), circleData, GL_STATIC_DRAW)
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(Float32), Ptr{Cvoid}(0))
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(Float32), Ptr{Cvoid}(2*sizeof(Float32)))
    glEnableVertexAttribArray(0)
    glEnableVertexAttribArray(1)


    v_texData = Vector{Float32}(undef, 3N)
    # (r=density,g=pressure,b=nothing)
    dp_texData = Vector{Float32}(undef, 3N)
    c_texData = Vector{Float32}(undef, 3N)
    for i in eachindex(fluid.collision)
        k = 3*(i-1)+1
        c_texData[k] = convert(Float32, fluid.collision[i])
        dp_texData[k] = convert(Float32, fluid.density[i])
        dp_texData[k+1] = convert(Float32, fluid.p[i])
        j = 2*(i-1)
        v_texData[k] = convert(Float32, fluid.vel[j+1])
        v_texData[k+1] = convert(Float32, fluid.vel[j+2])
    end

    textures = Vector{UInt32}(undef, 3)
    glGenTextures(3, Ref(textures, 1))
    c_tex = textures[1]
    v_tex = textures[2]
    dp_tex = textures[3]

    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, c_tex)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, Nx, Ny, 0, GL_RGB, GL_FLOAT, Ref(c_texData, 1))

    glActiveTexture(GL_TEXTURE1)
    glBindTexture(GL_TEXTURE_2D, v_tex)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, Nx, Ny, 0, GL_RGB, GL_FLOAT, Ref(v_texData, 1))

    glActiveTexture(GL_TEXTURE2)
    glBindTexture(GL_TEXTURE_2D, dp_tex)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, Nx, Ny, 0, GL_RGB, GL_FLOAT, Ref(dp_texData, 1))

    shader = createShader(joinpath(ShaderPath, "fluid.vert"), joinpath(ShaderPath, "fluid.frag"))

    glUseProgram(shader)
    glUniform2f(glGetUniformLocation(shader, "viewScale"), viewScale[1], viewScale[2])
    glUniform1i(glGetUniformLocation(shader, "collisionSampler"), 0)
    glUniform1i(glGetUniformLocation(shader, "velSampler"), 1)
    glUniform1i(glGetUniformLocation(shader, "densitySampler"), 2)

    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, c_tex)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, Nx, Ny, 0, GL_RGB, GL_FLOAT, c_texData)

    glActiveTexture(GL_TEXTURE1)
    glBindTexture(GL_TEXTURE_2D, v_tex)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, Nx, Ny, 0, GL_RGB, GL_FLOAT, v_texData)

    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, dp_tex);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, Nx, Ny, 0, GL_RGB, GL_FLOAT, dp_texData)

    solidShader = createShader(joinpath(ShaderPath, "circle.vert"), joinpath(ShaderPath, "circle.frag"))
    glUseProgram(solidShader)
    glUniform2f(glGetUniformLocation(solidShader, "viewScale"), viewScale[1], viewScale[2])

    glDisable(GL_DEPTH_TEST)

    frametimes_hist = fill(Float64(1/60), 32)


    currentTime = time()
    fpsDisplayUpdateTime = 0.25
    fpsDisplayElapsed = 0

    maximumTimestep = 1 / 30


    sourceAmount = 0.4

    shouldRun = true

    while shouldRun
        previousTime = currentTime
        currentTime = time()
        frameTime = currentTime - previousTime

        fpsDisplayElapsed += frameTime

        dt = min(maximumTimestep, frameTime)

        for i in Iterators.reverse(Iterators.drop(eachindex(frametimes_hist), 1)|>collect)
            frametimes_hist[i] = frametimes_hist[i-1]
        end
        frametimes_hist[1] = frameTime

        if fpsDisplayElapsed > fpsDisplayUpdateTime
            fpsDisplayElapsed = 0
            frametime_mean = mean(frametimes_hist)
            fps_mean = 1 / frametime_mean
            windowTitle = "Karman Vortex Street  -  $(round(fps_mean))"
            GLFW.SetWindowTitle(window, windowTitle)
        end


        if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS
            shouldRun = false
        end

        if GLFW.GetKey(window, GLFW.KEY_Z) == GLFW.PRESS
            zoom += zoom * zoomRate * dt
        end
        if GLFW.GetKey(window, GLFW.KEY_X) == GLFW.PRESS
            zoom -= zoom * zoomRate * dt
        end

        isPaused = GLFW.GetKey(window, GLFW.KEY_SPACE) == GLFW.PRESS

        #===== Physics =====#

        if !isPaused

            
            Swirl.timestepUpdate!(fluid, dt)
            for I in CartesianIndices(fluid.collision)
                x = (I[1] - 1) * fluid.dx[1]
                y = (I[2] - 1) * fluid.dx[2]
    
                r = norm([x, y] - CirclePos)
                if 1.0 <= r <= 1.3
                    fluid.density[I] += sourceAmount * dt
                end
            end
        end
        
        #===== Rendering =====#

        for i in eachindex(fluid.collision)
            k = 3*(i-1)+1
            dp_texData[k] = convert(Float32, fluid.density[i])
            dp_texData[k+1] = convert(Float32, fluid.p[i])
            j = 2*(i-1)
            v_texData[k] = convert(Float32, fluid.vel[j+1])
            v_texData[k+1] = convert(Float32, fluid.vel[j+2])
        end

        viewScale = [1, 1] / (maximum(0.5L) * zoom)

        
        glClearColor(0.0f0, 0.0f0, 0.0f0, 1.0f0)
        glClear(GL_COLOR_BUFFER_BIT)

        glUseProgram(shader)
        glUniform2f(glGetUniformLocation(shader, "viewScale"), viewScale[1], viewScale[2])
        
        glActiveTexture(GL_TEXTURE1)
        glBindTexture(GL_TEXTURE_2D, v_tex)
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, Nx, Ny, 0, GL_RGB, GL_FLOAT, v_texData)

        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, dp_tex);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, Nx, Ny, 0, GL_RGB, GL_FLOAT, dp_texData)
        
        
        
        glBindVertexArray(vaos[1])
        glDrawArrays(GL_TRIANGLES, 0, 6)
        
        glUseProgram(solidShader)
        glUniform2f(glGetUniformLocation(solidShader, "viewScale"), viewScale[1], viewScale[2])
        glBindVertexArray(vaos[2])
        glDrawArrays(GL_TRIANGLES, 0, 6)

        GLFW.SwapBuffers(window)
        GLFW.PollEvents()

        if (!shouldRun)
            GLFW.SetWindowShouldClose(window, true)
        end
    end


    glDeleteShader(shader)
    glDeleteVertexArrays(length(vaos), Ref(vaos, 1))
    glDeleteBuffers(length(vbos), Ref(vbos, 1))
    GLFW.DestroyWindow(window)
    GLFW.Terminate()
end

main()