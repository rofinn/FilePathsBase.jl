"""
    FileBuffer <: IO

A generic buffer type to provide an IO interface for none IO based path types.

NOTES:
- All `read` operations will read the entire file into the internal buffer at once.
  Subsequent calls to `read` will only operate on the internal buffer and will not access
  the filepath.
- All `write` operations will only write to the internal buffer and `flush`/`close` are
  required to update the filepath contents.
"""
struct FileBuffer <: IO
    path::AbstractPath
    io::IOBuffer
    readable::Bool
    writable::Bool
end

function FileBuffer(path::AbstractPath; readable=true, writable=false)
    FileBuffer(path, IOBuffer(), readable, writable)
end

Base.isreadable(buffer::FileBuffer) = buffer.readable
Base.iswritable(buffer::FileBuffer) = buffer.writable
Base.seek(buffer::FileBuffer, n::Integer) = seek(buffer.io, n)
Base.seekend(buffer::FileBuffer) = seekend(buffer.io)
Base.eof(buffer::FileBuffer) = eof(buffer.io)

function _read(buffer::FileBuffer)
    buffer.readable || throw(ArgumentError("read failed, FileBuffer is not readable"))

    # If our IOBuffer is empty then populate it with the
    # filepath contents
    if buffer.io.size == 0
        write(buffer.io, read(buffer.path))
        seekstart(buffer.io)
    end
end

function Base.read(buffer::FileBuffer)
    _read(buffer)
    read(buffer.io)
end

function Base.read(buffer::FileBuffer, ::Type{String})
    _read(buffer)
    read(buffer.io, String)
end

#=
NOTE: We need to define multiple methods because of ambiguity error with base IO methods.
=#
function Base.write(buffer::FileBuffer, x::Vector{UInt8})
    iswritable(buffer) || throw(ArgumentError("write failed, FileBuffer is not writeable"))
    write(buffer.io, x)
end

function Base.write(buffer::FileBuffer, x::String)
    iswritable(buffer) || throw(ArgumentError("write failed, FileBuffer is not writeable"))
    write(buffer.io, x)
end

function Base.flush(buffer::FileBuffer)
    if iswritable(buffer)
        seekstart(buffer)
        write(buffer.path, read(buffer.io))
    end
end

function Base.close(buffer::FileBuffer)
    flush(buffer)
    close(buffer.io)
end
