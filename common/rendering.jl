using GLFW, ModernGL


const ShaderPath = joinpath((@__DIR__), "shaders")

function createShader(vertPath, fragPath)
    ###### FIX THIS ##########
    fragSource = "#version 460 core\n"
    vertSource = "#version 460 core\n"

    open(vertPath) do io
        vertSource = vertSource * read(io, String)
    end

    open(fragPath) do io
        fragSource = fragSource * read(io, String)
        #read
    end

    vert = UInt32(0)
    frag = UInt32(0)

    infoLog = Vector{UInt8}(undef, 512)

    vert = glCreateShader(GL_VERTEX_SHADER)
    #vert_cstr = Ref(codeunits(vertSource)[:], 1)
    vert_cstr = Vector{Cchar}(undef, 0)
    for c in vertSource
        push!(vert_cstr, Cchar(c))
    end
    ptrs1 = Ptr{UInt8}[pointer(vert_cstr)]
    glShaderSource(vert, 1, ptrs1, C_NULL)
    glCompileShader(vert)
    success = Ref{Cint}(0)
    glGetShaderiv(vert, GL_COMPILE_STATUS, success)

    if success[] != 1
        glGetShaderInfoLog(vert, 512, C_NULL, infoLog)
        println(
            String(collect(Iterators.takewhile(!=('\0'), Char.(infoLog))))
        )
    end

    frag = glCreateShader(GL_FRAGMENT_SHADER)
    #frag_cstr = map(Cchar, codeunits(fragSource)) |> collect
    frag_cstr = Vector{Cchar}(undef, 0)
    for c in fragSource
        push!(frag_cstr, Cchar(c))
    end
    ptrs2 = Ptr{UInt8}[pointer(frag_cstr)]
    glShaderSource(frag, 1, ptrs2, C_NULL)
    glCompileShader(frag)
    glGetShaderiv(frag, GL_COMPILE_STATUS, success)

    if success[] != 1
        glGetShaderInfoLog(frag, 512, C_NULL, infoLog)
        println(
            String(collect(Iterators.takewhile(!=('\0'), Char.(infoLog))))
        )
    end

    shaderProgram = glCreateProgram()
    glAttachShader(shaderProgram, vert)
    glAttachShader(shaderProgram, frag)
    glLinkProgram(shaderProgram)
    glDeleteShader(vert)
    glDeleteShader(frag)

    return shaderProgram
end

function renderInit(title)
    GLFW.Init()
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 4)#########################################
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 6)#########################################

    width = 1200
    height = 1200

    window = GLFW.CreateWindow(width, height, title)

    GLFW.MakeContextCurrent(window)

    return window
end