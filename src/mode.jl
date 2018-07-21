"""
The following file contains simple abstractions to make working with
posix permissions easier in julia.

For now we're focused on user permissions.

A lot of the low level permissions code below and the corresponding
constants have been translated from cpython's Lib/stat.py file.

https://github.com/python/cpython/blob/master/Lib/stat.py
"""
struct Mode
    m::UInt64
end

function Mode(;user::UInt8=0o0, group::UInt8=0o0, other::UInt8=0o0,)
    @assert user <= 0o7 && group <= 0o7 && other <= 0o7

    Mode(user * USER_COEFF | group * GROUP_COEFF | other * OTHER_COEFF)
end

function Mode(mode::UInt8, usr_grps::Symbol...)
    user = group = other = 0o0

    for usr_grp in usr_grps
        if usr_grp == :ALL
            user = group = other = mode
            break
        elseif usr_grp == :USER
            user = mode
        elseif usr_grp == :GROUP
            group = mode
        elseif usr_grp == :OTHER
            other = mode
        else
            throw(ArgumentError(
                "$usr_grp not a valid symbol only " *
                ":ALL, :USER, :GROUP and :OTHER are accepted."
            ))
        end
    end

    return Mode(user=user, group=group, other=other)
end

Base.show(io::IO, mode::Mode) = print(io, string(mode))
Base.String(mode::Mode) = string(mode)

Base.:-(a::Mode, b::Mode) = Mode(a.m & ~b.m)
Base.:+(a::Mode, b::Mode) = Mode(a.m | b.m)

executable(usr_grps::Symbol...) = Mode(EXEC, usr_grps...)
readable(usr_grps::Symbol...) = Mode(READ, usr_grps...)
writable(usr_grps::Symbol...) = Mode(WRITE, usr_grps...)

function isexecutable(mode::Mode, usr_grp::Symbol)
    mask = S_IXOTH | S_IXGRP | S_IXUSR

    if usr_grp == :OTHER
        mask = S_IXOTH
    elseif usr_grp == :GROUP
        mask = S_IXGRP
    elseif usr_grp == :USER
        mask = S_IXUSR
    end

    return mode.m & mask == mask
end

function Base.iswritable(mode::Mode, usr_grp::Symbol)
    mask = S_IWOTH | S_IWGRP | S_IWUSR

    if usr_grp == :OTHER
        mask = S_IWOTH
    elseif usr_grp == :GROUP
        mask = S_IWGRP
    elseif usr_grp == :USER
        mask = S_IWUSR
    end

    return mode.m & mask == mask
end

function Base.isreadable(mode::Mode, usr_grp::Symbol)
    mask = S_IROTH | S_IRGRP | S_IRUSR

    if usr_grp == :OTHER
        mask = S_IROTH
    elseif usr_grp == :GROUP
        mask = S_IRGRP
    elseif usr_grp == :USER
        mask = S_IRUSR
    end

    return mode.m & mask == mask
end

Base.oct(mode::Mode) = oct(mode.m)
raw(mode::Mode) = mode.m

"""Return True if mode is from a directory."""
Base.isdir(mode::Mode) = _meta(mode.m) == S_IFDIR

"""Return True if mode is from a regular file."""
Base.isfile(mode::Mode) = _meta(mode.m) == S_IFREG

"""Return True if mode is from a symbolic link."""
Base.islink(mode::Mode) = _meta(mode.m) == S_IFLNK

"""Return True if mode is from a socket."""
Base.issocket(mode) = _meta(mode.m) == S_IFSOCK

"""Return True if mode is from a FIFO (named pipe)."""
Base.isfifo(mode::Mode) = _meta(mode.m) == S_IFIFO

"""Return True if mode is from a character special device file."""
Base.ischardev(mode::Mode) = _meta(mode.m) == S_IFCHR

"""Return True if mode is from a block special device file."""
Base.isblockdev(mode::Mode) = _meta(mode.m) == S_IFBLK


"""Convert a file's mode to a string of the form '-rwxrwxrwx'."""
function Base.string(mode::Mode)
    perm = []
    for table in FILEMODE_TABLE
        found = false
        for (bit, char) in table
            if mode.m & bit == bit
                push!(perm, char)
                found = true
                break
            end
        end
        if !found
            push!(perm, '-')
        end
    end

    return join(perm)
end

"""
Return the portion of the file's mode that can be set by
os.chmod().
"""
_mode(mode) = mode & 0o7777

"""
Return the portion of the file's mode that describes the
file type.
"""
_meta(mode) = mode & 0o170000
