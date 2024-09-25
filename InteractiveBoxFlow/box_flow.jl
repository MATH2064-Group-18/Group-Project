using Swirl
using ModernGL, GLFW
using Statistics
using LinearAlgebra

include("../common/rendering.jl")
include("../common/geometry.jl")

const Field_T = Float64

const Nx = 256
const Ny = 256
const N = Nx*Ny
const Ns = [Nx, Ny]

const L = Field_T[10, 10]
const H = @. L / 2

const Demo_Title = "Box Flow"

function main()

    fluid = let
        T = Field_T
        l = L[:]
        n = (Nx, Ny)
        Dx = @. l / (n-1)
        v = zeros(T, 2, n[1], n[2])
        p = zeros(T, n[1], n[2])
        d = zeros(T, n[1], n[2])
        
        v[1, :, :] .= 2
        coll = ones(T, n[1], n[2])
        for i = 1:Nx
            for j = 1:Ny
                x = (i-1) * Dx[1]
                y = (j-1) * Dx[2]
                if i == 1 || i == Nx || j == 1 || j == Nx
                    coll[i, j] = -1
                end
            end
        end

        
        Swirl.Fluid(Dx, v, coll, p, d)
    end
    window = renderInit(Demo_Title)

    geos = Vector{Geometry}(undef, 0)
    push!(
        geos, 
        Geometry(
            Circle(), @MMatrix(Field_T[0.2 0; 0 0.2]), 
            MVector{2, Field_T}(2.0, -1.5)+H, 
            MVector{2, Field_T}(0, 0), 
            zero(Field_T), true, false
        )
    )
    push!(
        geos, 
        Geometry(
            Square(), @MMatrix(Field_T[1 0; 0 1]), 
            MVector{2, Field_T}(-1.0, 0.0)+H, 
            MVector{2, Field_T}(0, 0), 
            zero(Field_T), true, false
        )
    )
    push!(
        geos, 
        Geometry(
            Square(), @MMatrix(Field_T[1 0; 0 1]), 
            MVector{2, Field_T}(2.0, 1.0)+H, 
            MVector{2, Field_T}(0, 0), 
            zero(Field_T), true, false
        )
    )
    push!(
        geos, 
        Geometry(
            Square(), @MMatrix(Field_T[1.2 0; 0 1.2]), 
            MVector{2, Field_T}(-1.0, 0.0)+H, 
            MVector{2, Field_T}(0, 0), 
            zero(Field_T), false, true
        )
    )
    push!(
        geos, 
        Geometry(
            Square(), @MMatrix(Field_T[1.2 0; 0 1.2]), 
            MVector{2, Field_T}(2.0, 1.0)+H, 
            MVector{2, Field_T}(0, 0), 
            zero(Field_T), false, true
        )
    )



    planeData = collect(transpose([
        -1.0f0 -1.0f0 0.0f0 0.0f0
        1.0f0 -1.0f0  1.0f0 0.0f0
        -1.0f0 1.0f0  0.0f0 1.0f0
        1.0f0 -1.0f0  1.0f0 0.0f0
        1.0f0 1.0f0   1.0f0 1.0f0
        -1.0f0 1.0f0  0.0f0 1.0f0
    ]))

    viewScale = Float32[1, 1]

    # Copy Geometry to OpenGL buffers

    vaos = UInt32[0]
    vbos = UInt32[0]

    ModernGL.glGenVertexArrays(length(vaos), Ref(vaos, 1))
    ModernGL.glGenBuffers(length(vbos), Ref(vbos, 1))

    glBindVertexArray(vaos[1])
    glBindBuffer(GL_ARRAY_BUFFER, vbos[1])
    glBufferData(GL_ARRAY_BUFFER, length(planeData) * sizeof(Float32), planeData, GL_STATIC_DRAW)
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(Float32), Ptr{Cvoid}(0))
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(Float32), Ptr{Cvoid}(2*sizeof(Float32)))
    glEnableVertexAttribArray(0)
    glEnableVertexAttribArray(1)

    
    v_texData = Vector{Float32}(undef, 3N)
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
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, Nx, Ny, 0, GL_RGB, GL_FLOAT, Ref(dp_texData, 1))

    fluid_shader = createShader(joinpath(ShaderPath, "fluid.vert"), joinpath(ShaderPath, "fluid.frag"))

    glUseProgram(fluid_shader)
    glUniform2f(glGetUniformLocation(fluid_shader, "viewScale"), viewScale[1], viewScale[2])
    glUniform1i(glGetUniformLocation(fluid_shader, "collisionSampler"), 0)
    glUniform1i(glGetUniformLocation(fluid_shader, "velSampler"), 1)
    glUniform1i(glGetUniformLocation(fluid_shader, "densitySampler"), 2)

    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, c_tex)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, Nx, Ny, 0, GL_RGB, GL_FLOAT, c_texData)

    glActiveTexture(GL_TEXTURE1)
    glBindTexture(GL_TEXTURE_2D, v_tex)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, Nx, Ny, 0, GL_RGB, GL_FLOAT, v_texData)

    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, dp_tex);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, Nx, Ny, 0, GL_RGB, GL_FLOAT, dp_texData)

    glDisable(GL_DEPTH_TEST)

    frametimes_hist = fill(Float64(1/60), 32)

    currentTime = time()
    fpsDisplayUpdateTime = 0.25
    fpsDisplayElapsed = 0

    maximumTimestep = 1 / 30


    sourceAmount = 0.2









    shouldRun = true

    while shouldRun
        previousTime = currentTime
        currentTime = time()
        frameTime = currentTime - previousTime
        fpsDisplayElapsed += frameTime

        dt = convert(Field_T, min(maximumTimestep, frameTime))
        
        for i in Iterators.reverse(Iterators.drop(eachindex(frametimes_hist), 1)|>collect)
            frametimes_hist[i] = frametimes_hist[i-1]
        end
        frametimes_hist[1] = frameTime

        if fpsDisplayElapsed > fpsDisplayUpdateTime
            fpsDisplayElapsed = 0
            frametime_mean = mean(frametimes_hist)
            fps_mean = 1 / frametime_mean
            windowTitle = "$(Demo_Title)  -  $(round(fps_mean))"
            GLFW.SetWindowTitle(window, windowTitle)
        end

        if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS
            shouldRun = false
        end

        for I in CartesianIndices(fluid.p)
            fluid.collision[I] = 1
            if Base.Cartesian.@nany 2 j -> (I[j] == 1 || I[j] == Ns[j])
                fluid.collision[I] = -1
            end
        end

        for g in geos
            rasterise!(fluid, g, sourceAmount * dt)
        end

        Swirl.timestepUpdate!(fluid, dt)


        for i in eachindex(fluid.collision)
            k = 3*(i-1)+1
            dp_texData[k] = convert(Float32, fluid.density[i])
            dp_texData[k+1] = convert(Float32, fluid.p[i])
            j = 2*(i-1)
            v_texData[k] = convert(Float32, fluid.vel[j+1])
            v_texData[k+1] = convert(Float32, fluid.vel[j+2])
        end

        # Rendering #

        glClearColor(0.0f0, 0.0f0, 0.0f0, 1.0f0)
        glClear(GL_COLOR_BUFFER_BIT)
        glUseProgram(fluid_shader)

        glActiveTexture(GL_TEXTURE1)
        glBindTexture(GL_TEXTURE_2D, v_tex)
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, Nx, Ny, 0, GL_RGB, GL_FLOAT, v_texData)

        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, dp_tex);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, Nx, Ny, 0, GL_RGB, GL_FLOAT, dp_texData)

        glActiveTexture(GL_TEXTURE0)
        glBindTexture(GL_TEXTURE_2D, c_tex)
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, Nx, Ny, 0, GL_RGB, GL_FLOAT, c_texData)

        glBindVertexArray(vaos[1])
        glDrawArrays(GL_TRIANGLES, 0, 6)

        if (!shouldRun)
            GLFW.SetWindowShouldClose(window, true)
        end
        GLFW.SwapBuffers(window)
        GLFW.PollEvents()
    end

    glDeleteShader(fluid_shader)
    glDeleteVertexArrays(length(vaos), Ref(vaos, 1))
    glDeleteBuffers(length(vbos), Ref(vbos, 1))
    GLFW.DestroyWindow(window)
    GLFW.Terminate()

end

function rasterise!(fluid, geo, sval)
    if !(geo.isCollider || geo.isSource)
        return
    end
    J = let
        R = 2 * maximum(abs, geo.transform)
        l1 = @. floor(Int, (geo.pos - R) / fluid.dx)
        l2 = @. ceil(Int, (geo.pos + R) / fluid.dx)
        S = size(fluid.collision)
        k1 = @. max(l1, 1)
        k2 = @. min(l2, S)
        U = Tuple(map(i -> k1[i]:k2[i], eachindex(k1)))
        CartesianIndices(U)
    end
    q = sval
    F = inv(geo.transform)
    for I in J
        r = SA[(I[1] - 1) * fluid.dx[1], (I[2] - 1) * fluid.dx[2]] - geo.pos
        pos = F * r
        hit = primIntersect(pos, geo.prim)
        if hit
            if geo.isCollider
                fluid.collision[I] = -1
                @. fluid.vel[:, I] = geo.v + geo.ω * SA[r[2], -r[1]]
            end
            if geo.isSource
                if fluid.collision[I] > 0
                    fluid.density[I] += q
                end
            end
        end
    end
end

main()