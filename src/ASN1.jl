module ASN1
export parse_tag, ASNTag
import Base.==

struct ASNTag
    tag_class::UInt8
    tag_encoding::Bool
    tag_number_lenght::UInt
    tag_number::BitVector
    tag_length_length::UInt
    content_length_indefinite::Bool
    content_length::UInt
    content::Vector{UInt8}
    children::Vector{ASNTag}
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

function promote_vector_to_uint(bytes::Vector{UInt8})
    result = zero(UInt128)
    for b in bytes
        result = (result << 8) | b
    end
    return result
end

function parse_tag(buff::Vector{UInt8})
    _class = buff[1] >> 6
    _encoding = (buff[1] & 0b00100000) == 0b00100000
    tag_number_long_form = (buff[1] & 0b00011111) == 0b00011111
    tag_number = BitVector()
    number_lenght = 0
    offset = 1
    if !tag_number_long_form
        append!(tag_number, [(buff[offset] & 0b00010000) == 0b00010000,
                             (buff[offset] & 0b00001000) == 0b00001000,
                             (buff[offset] & 0b00000100) == 0b00000100,
                             (buff[offset] & 0b00000010) == 0b00000010,
                             (buff[offset] & 0b00000001) == 0b00000001])
        offset += 1
    else
        offset += 1
        while true
            append!(tag_number, [(buff[offset] & 0b01000000) == 0b01000000,
                                 (buff[offset] & 0b00100000) == 0b00100000,
                                 (buff[offset] & 0b00010000) == 0b00010000,
                                 (buff[offset] & 0b00001000) == 0b00001000,
                                 (buff[offset] & 0b00000100) == 0b00000100,
                                 (buff[offset] & 0b00000010) == 0b00000010,
                                 (buff[offset] & 0b00000001) == 0b00000001])
            if (buff[offset] & 0b10000000) != 0b10000000
                number_lenght += 1
                offset += 1
                break
            end
            number_lenght += 1
            offset += 1
        end
    end
    indefinitive_form = buff[offset] == 0b10000000
    length_length = 0
    if !indefinitive_form
        short_form = (buff[offset] & 0b10000000) == 0
        if short_form
            content_length = buff[offset] & 0b01111111
            length_length = 1
            offset += 1
        else
            c_l_octet_count = buff[offset] & 0b01111111
            length_length = 1
            offset += 1
            content_length = promote_vector_to_uint(buff[offset:offset + c_l_octet_count - 1])
            offset += c_l_octet_count
            length_length += c_l_octet_count
        end
    else
        length_length = 1
        offset += 1
        idx = findfirst(UInt8[0, 0], buff[offset:end])[1]
        content_length = length(offset:offset + idx - 2) 
    end
    content = buff[offset:offset + content_length - 1]
    return ASNTag(_class, 
                  _encoding,
                  number_lenght,
                  tag_number,
                  length_length,
                  indefinitive_form,
                  content_length,
                  content,
                  [])
end
end
