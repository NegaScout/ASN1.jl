module ASN1
import Base.==

struct ASNTag
    class::UInt8
    encoding::Bool
    number::BitVector
    len::UInt
    content::Vector{UInt8}
end

function ==(a::ASNTag, b::ASNTag)
    return a.class == b.class && a.encoding == b.encoding && a.number == b.number && a.len == b.len && a.content == b.content
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
    tag = BitVector()
    offset = 1
    if !tag_number_long_form
        append!(tag, [(buff[offset] & 0b00010000) == 0b00010000,
                      (buff[offset] & 0b00001000) == 0b00001000,
                      (buff[offset] & 0b00000100) == 0b00000100,
                      (buff[offset] & 0b00000010) == 0b00000010,
                      (buff[offset] & 0b00000001) == 0b00000001])
        offset += 1
    else
        offset += 1
        while true
            append!(tag, [(buff[offset] & 0b01000000) == 0b01000000,
                          (buff[offset] & 0b00100000) == 0b00100000,
                          (buff[offset] & 0b00010000) == 0b00010000,
                          (buff[offset] & 0b00001000) == 0b00001000,
                          (buff[offset] & 0b00000100) == 0b00000100,
                          (buff[offset] & 0b00000010) == 0b00000010,
                          (buff[offset] & 0b00000001) == 0b00000001])
            if (buff[offset] & 0b10000000) != 0b10000000
                offset += 1
                break
            end
            offset += 1
        end
    end
    indefinitive_form = buff[offset] == 0b10000000
    if !indefinitive_form
        short_form = (buff[offset] & 0b10000000) == 0
        if short_form
            content_length = buff[offset] & 0b01111111
            offset += 1
        else
            c_l_octet_count = buff[offset] & 0b01111111
            offset += 1
            content_length = promote_vector_to_uint(buff[offset:offset + c_l_octet_count - 1])
            offset += c_l_octet_count
        end
    else
        offset += 1
        idx = findfirst(UInt8[0, 0], buff[offset:end])[1]
        content_length = length(offset:offset + idx - 2) 
    end
    content = buff[offset:offset + content_length - 1]
    return ASNTag(_class, 
                  _encoding,
                  tag,
                  content_length,
                  content)
end

end
