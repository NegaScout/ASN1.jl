export parse_tag, ASNTag
import Base.==

struct ASNTag
    tag_class::UInt8
    tag_encoding::Bool
    tag_number_lenght::UInt64
    tag_number::UInt64
    tag_length_length::UInt64
    content_length_indefinite::Bool
    content_length::UInt64
    content::Vector{UInt8}
    children::Vector{ASNTag}
end

function Base.show(io::IO, tag::ASNTag)
    if isempty(tag.children)
        print(io, "(",
                    tag.tag_class, ", ",
                    tag.tag_encoding, ", ",
                    tag.tag_number_lenght, ", ",
                    tag.tag_number, ", ",
                    tag.tag_length_length, ", ",
                    tag.content_length_indefinite, ", ",
                    tag.content_length, ", ",
                    tag.content, ", ASNTag[])")
    else
        print(io, "(",
                    tag.tag_class, ", ",
                    tag.tag_encoding, ", ",
                    tag.tag_number_lenght, ", ",
                    tag.tag_number, ", ",
                    tag.tag_length_length, ", ",
                    tag.content_length_indefinite, ", ",
                    tag.content_length, ", ",
                    tag.content, ", ASNTag[...])")
    end
end

function ==(a::ASNTag, b::ASNTag)
    return (a.tag_class == b.tag_class &&
            a.tag_encoding == b.tag_encoding &&
            a.tag_number == b.tag_number &&
            a.tag_number_lenght == b.tag_number_lenght &&
            a.tag_length_length == b.tag_length_length &&
            a.content_length == b.content_length &&
            a.content == b.content &&
            a.children == b.children)
end

function parse_tag(buff::Vector{UInt8})
    tag_class = buff[1] >> 6
    tag_encoding = (buff[1] & 0b00100000) == 0b00100000
    tag_number_long_form = (buff[1] & 0b00011111) == 0b00011111
    tag_number = UInt64(0)
    tag_number_lenght = 0
    offset = 1
    if !tag_number_long_form
        tag_number = UInt64(buff[offset] & 0b00011111)
        offset += 1
    else
        offset += 1
        while true
            tag_number = (tag_number << 7) | UInt64(buff[offset] & 0b01111111)
            if (buff[offset] & 0b10000000) != 0b10000000
                tag_number_lenght += 1
                offset += 1
                break
            end
            tag_number_lenght += 1
            offset += 1
        end
    end
    content_length_indefinite = buff[offset] == 0b10000000
    tag_length_length = 0
    if !content_length_indefinite
        short_form = (buff[offset] & 0b10000000) == 0
        if short_form
            content_length = buff[offset] & 0b01111111
            tag_length_length = 1
            offset += 1
        else
            c_l_octet_count = buff[offset] & 0b01111111
            tag_length_length = 1
            offset += 1
            cl_buffer_slice = offset:offset + c_l_octet_count - 1
            cl_buffer = vcat(zeros(UInt8, 8 - length(cl_buffer_slice)), buff[cl_buffer_slice])
            content_length = reinterpret(UInt64, reverse(cl_buffer))[1]
            offset += c_l_octet_count
            tag_length_length += c_l_octet_count
        end
    else
        tag_length_length = 1
        offset += 1
        idx = findfirst(UInt8[0, 0], buff[offset:end])[1]
        content_length = length(offset:offset + idx - 2) 
    end
    content = buff[offset:offset + content_length - 1]
    return ASNTag(tag_class, 
                  tag_encoding,
                  tag_number_lenght,
                  tag_number,
                  tag_length_length,
                  content_length_indefinite,
                  content_length,
                  content,
                  [])
end

function serialized_length(tag::ASNTag)
    return 1 + tag.tag_number_lenght + tag.tag_length_length + tag.content_length + 2*tag.content_length_indefinite
end

function parse_asn1(buff::Vector{UInt8})
    tag = parse_tag(buff)
    if tag.tag_encoding
        tmp = parse_asn1_children(tag.content)
        append!(tag.children, tmp)
        resize!(tag.content, 0)
    end
    return tag
end

function parse_asn1_children(buff::Vector{UInt8})
    children = ASNTag[]
    idx = 1
    while idx <= length(buff)
        child = parse_asn1(buff[idx:end])
        push!(children, child)
        idx += serialized_length(child)
    end
    return children
end
