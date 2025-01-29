using Dates

import Base.Filesystem: StatStruct

struct Status
    device::UInt64
    inode::UInt64
    mode::Mode
    nlink::Int64
    uid::UInt
    gid::UInt
    rdev::UInt64
    size::Int64
    blksize::Int64
    blocks::Int64
    mtime::DateTime
    ctime::DateTime
end

function Status(s::StatStruct)
    return Status(
        s.device,
        s.inode,
        Mode(s.mode),
        s.nlink,
        s.uid,
        s.gid,
        s.rdev,
        s.size,
        s.blksize,
        s.blocks,
        unix2datetime(s.mtime),
        unix2datetime(s.ctime),
    )
end

function Base.getproperty(s::Status, sym::Symbol)
    if sym === :user
        return User(getfield(s, :uid))
    elseif sym === :group
        return Group(getfield(s, :gid))
    else
        return getfield(s, sym)
    end
end

function Base.show(io::IO, s::Status)
    output =
        "Status(\n" *
        "  device = $(s.device),\n" *
        "  inode = $(s.inode),\n" *
        "  mode = $(s.mode),\n" *
        "  nlink = $(s.nlink),\n" *
        "  uid = $(s.user),\n" *
        "  gid = $(s.group),\n" *
        "  rdev = $(s.rdev),\n" *
        "  size = $(s.size) ($(_datasize(s.size))),\n" *
        "  blksize = $(s.blksize) ($(_datasize(s.blksize))),\n" *
        "  blocks = $(s.blocks),\n" *
        "  mtime = $(s.mtime),\n" *
        "  ctime = $(s.ctime),\n)"

    return print(io, output)
end
