export deserialize_ber, serialize_ber, ASNTag
import Base.==

function enum_defined(T::Type{<:Enum}, x::Integer)
    return haskey(Base.Enums.namemap(T), x)
end

@enum TagClass begin
    universal=0b00
    application=0b01
    context_specific=0b10
    private=0b11
end

@enum TagEncoding begin
    primitive=false
    constructed=true
end

@enum ContentLengthType begin
    definite_short=0x0
    definite_long=0x01
    indefinite=0x02
end

@enum ClassUniversalTagNumber begin
    u_reserved = 0
    u_boolean = 1
    u_integer = 2
    u_bit_string = 3
    u_octet_string = 4
    u_null = 5
    u_object_identifier = 6
    u_object_descriptor = 7
    u_external = 8
    u_real = 9
    u_enumerated = 10
    u_embedded_pdv = 11
    u_utf8_string = 12
    u_relative_oid = 13
    u_reserved_14 = 14
    u_reserved_15 = 15
    u_sequence = 16
    u_set = 17
    u_char_18 = 18
    u_char_19 = 19
    u_char_20 = 20
    u_char_21 = 21
    u_char_22 = 22
    u_time_type_23 = 23
    u_time_type_24 = 24
    u_char_25 = 25
    u_char_26 = 26
    u_char_27 = 27
    u_char_28 = 28
    u_char_29 = 29
    u_char_30 = 30
    u_reserved_31 = 31
end

struct ASNTag
    tag_class::UInt8
    tag_encoding::Bool
    tag_number_long_form::Bool
    tag_number_lenght::UInt64
    tag_number::UInt64
    tag_length_length::UInt64
    content_length_type::UInt8
    content::Vector{UInt8}
    children::Vector{ASNTag}
end

function Base.show(io::IO, tag::ASNTag)
    _tag_number = tag.tag_number
    if enum_defined(ClassUniversalTagNumber, _tag_number)
        _tag_number = ClassUniversalTagNumber(_tag_number)
    end
    vals = [TagClass(tag.tag_class),
            TagEncoding(tag.tag_encoding),
            tag.tag_number_long_form,
            tag.tag_number_lenght,
            _tag_number,
            tag.tag_length_length,
            ContentLengthType(tag.content_length_type)]
    if isempty(tag.children) && length(tag.content) == 0
        append!(vals, ["UInt8[]", "ASNTag[]"])
    elseif isempty(tag.children)
        append!(vals, ["UInt8[...]", "ASNTag[]"])
    else
        append!(vals, ["UInt8[]", "ASNTag[...]"])
    end
    print(io, "ASNTag(", join(vals, ", "), ")")
end

function ==(a::ASNTag, b::ASNTag)
    return (a.tag_class == b.tag_class &&
            a.tag_encoding == b.tag_encoding &&
            a.tag_number_long_form == b.tag_number_long_form &&
            a.tag_number_lenght == b.tag_number_lenght &&
            a.tag_number == b.tag_number &&
            a.tag_length_length == b.tag_length_length &&
            a.content_length_type == b.content_length_type &&
            a.content == b.content &&
            a.children == b.children)
end

"""
    deserialize_tag(buff::Vector{UInt8})
Deserialize a BER tag (also deserializes DER/CER)
"""
function deserialize_tag(buff::Vector{UInt8})
    tag_class = buff[1] >> 6
    tag_encoding = (buff[1] & 0b00100000) == 0b00100000
    tag_number_long_form = Bool((buff[1] & 0b00011111) == 0b00011111)
    tag_number = UInt64(0)
    tag_number_lenght = UInt64(0)
    offset = UInt64(1)
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
    tag_length_length = UInt64(0)
    short_form = false
    if !content_length_indefinite
        short_form = (buff[offset] & 0b10000000) == 0
        if short_form
            content_length = UInt64(buff[offset] & 0b01111111)
            tag_length_length = UInt64(1)
            offset += 1
        else
            c_l_octet_count = UInt64(buff[offset] & 0b01111111)
            tag_length_length = UInt64(1)
            offset += 1
            cl_buffer_slice = offset:offset + c_l_octet_count - 1
            cl_buffer = vcat(zeros(UInt8, 8 - length(cl_buffer_slice)), buff[cl_buffer_slice])
            content_length = reinterpret(UInt64, reverse(cl_buffer))[1]
            offset += c_l_octet_count
            tag_length_length += c_l_octet_count
        end
    else
        tag_length_length = UInt64(1)
        offset += 1
        pattern_idx = findfirst(UInt8[0, 0], buff[offset:end])
        if isnothing(pattern_idx)
            return nothing
        end
        idx = pattern_idx[1]
        content_length = length(offset:offset + idx - 2) 
    end
    content = buff[offset:offset + content_length - 1]

    content_length_type = UInt8(0)
    if content_length_indefinite
        content_length_type = 2
    elseif !short_form
        content_length_type = 1
    else
        content_length_type = 0
    end

    return ASNTag(tag_class, 
                  tag_encoding,
                  tag_number_long_form,
                  tag_number_lenght,
                  tag_number,
                  tag_length_length,
                  content_length_type,
                  content,
                  [])
end

"""
    deserialize_ber(buff::Vector{UInt8})
Deserialize a whole BER "document" recursively (also deserializes DER/CER)
"""
function deserialize_ber(buff::Vector{UInt8})
    tag = deserialize_tag(buff)
    if isnothing(tag)
        return nothing
    elseif tag.tag_encoding
        tmp = deserialize_ber_children(tag.content)
        append!(tag.children, tmp)
    end
    return tag
end

"""
    deserialize_ber_children(buff::Vector{UInt8})
Deserialize a BER tag's constructed contents recursively (also deserializes DER/CER)
"""
function deserialize_ber_children(buff::Vector{UInt8})
    children = ASNTag[]
    idx = 1
    while idx <= length(buff)
        child = deserialize_ber(buff[idx:end])
        if isnothing(child)
            return nothing
        end
        push!(children, child)
        idx += serialized_length(child)
    end
    return children
end

"""
    serialized_length(tag::ASNTag)
Returns length in bytes of ASNTag in serialized form
"""
function serialized_length(tag::ASNTag)
    return 1 + tag.tag_number_lenght + tag.tag_length_length + length(tag.content) + 2*(tag.content_length_type == 2)
end

"""
    serialize_ber(tag::ASNTag)
Serializes BER tree into binary format
"""
function serialize_ber(tag::ASNTag)
    buffer = Vector{UInt8}(undef, serialized_length(tag))
    offset = UInt64(1)
    buffer[offset] = (tag.tag_class << 6) | (tag.tag_encoding << 5)
    if !tag.tag_number_long_form
        buffer[offset] |= tag.tag_number
        offset += 1
    else
        buffer[offset] |= 0b00011111
        offset += 1
        tag_number = tag.tag_number
        for _ in 1:(tag.tag_number_lenght - 1)
            curr_segment = ((tag_number >> 7) & 0b01111111)
            buffer[offset] = 0b10000000 | curr_segment
            tag_number = tag_number >> 7
            offset += 1
        end
        buffer[offset] = tag_number
        offset += 1
    end

    if tag.content_length_type == 0
        buffer[offset] = length(tag.content)
        offset += 1
    elseif tag.content_length_type == 2
        buffer[offset] = 0b10000000
        offset += 1
        buffer[length(buffer) - 1] = 0
        buffer[length(buffer)] = 0
    else
        c_l_octet_count = tag.tag_length_length - 1
        buffer[offset] = 0b10000000 | c_l_octet_count
        offset += 1
        content_length = length(tag.content)
        tmp = reinterpret(UInt8, UInt64[content_length])
        cl_buffer = reverse(tmp[1:c_l_octet_count])
        copyto!(buffer,
                offset,
                cl_buffer,
                1,
                c_l_octet_count)
        offset += c_l_octet_count
    end
    copyto!(buffer,
            offset,
            tag.content,
            1,
            length(tag.content))
    return buffer
end
