function uuid4()
    u = rand(UInt128)
    u &= 0xffffffffffff0fff3fffffffffffffff
    u |= 0x00000000000040008000000000000000
    return UUID(u)
end
# Mostly copied from https://github.com/IainNZ/Humanize.jl/blob/master/src/Humanize.jl#L27
function _datasize(bytes::Number)
    base = 1024.0
    nbytes = float(bytes)
    unit = base
    suffix = first(DATA_SUFFIX)

    for (i, s) in enumerate(DATA_SUFFIX)
        unit = base^i

        if nbytes < unit
            suffix = s
            break
        end
    end
    return string(round(base * nbytes / unit; digits=1)) * suffix
end
