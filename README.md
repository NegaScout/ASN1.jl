# ASN1.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://NegaScout.github.io/ASN1.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://NegaScout.github.io/ASN1.jl/dev/)
[![Build Status](https://github.com/NegaScout/ASN1.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/NegaScout/ASN1.jl/actions/workflows/CI.yml?query=branch%3Amain)

`ASN1.jl` is a small Julia package for working with ASN.1 BER-encoded data. It focuses on turning BER/DER/CER byte buffers into a tree of `ASNTag` values and serializing those trees back to bytes.

## Features

- Deserialize BER-encoded buffers into an `ASNTag` tree.
- Serialize `ASNTag` values back into BER form.
- Support primitive and constructed tags.
- Preserve tag metadata such as class, encoding, tag number, and content length form.
- Integrate with `AbstractTrees.jl`, so parsed values can be traversed like a tree.

## Installation

Install from the Julia package manager:

```julia
using Pkg
Pkg.add(url="https://github.com/NegaScout/ASN1.jl")
```

Then load the package:

```julia
using ASN1
```

## Quick start

```julia
using ASN1

# A primitive universal tag with a one-byte payload.
bytes = UInt8[0x01, 0x01, 0xFF]
tag = deserialize_ber(bytes)

println(tag)
# ASNTag(universal, primitive, false, 0, u_boolean, 1, definite_short, UInt8[...], ASNTag[])

roundtrip = serialize_ber(tag)
@assert roundtrip == bytes
```

## Data model

The package represents BER data with the `ASNTag` struct. Each node stores:

- the tag class,
- whether the tag is primitive or constructed,
- the tag number and whether it uses long-form encoding,
- the encoded content length form,
- the raw content bytes, and
- child tags for constructed values.

Constructed tags are parsed recursively. Because `ASNTag` implements `AbstractTrees.children`, tree utilities from `AbstractTrees.jl` can be used directly.

## Core API

### `deserialize_ber(buff::Vector{UInt8})`

Parses an entire BER document recursively and returns an `ASNTag`. If the buffer does not contain a valid tag structure, it returns `nothing`.

### `serialize_ber(tag::ASNTag)`

Serializes an `ASNTag` tree back into BER bytes.

### `deserialize_tag(buff::Vector{UInt8})`

Parses a single BER tag without recursively deserializing child content.

### `serialized_length(tag::ASNTag)`

Returns the number of bytes the tag occupies in serialized form.

## Example: parsing a long-form length

```julia
using ASN1

bytes = UInt8[0x01, 0x82, 0x00, 0x01, 0x00]
tag = deserialize_ber(bytes)

@assert tag.tag_length_length == 3
@assert tag.content_length_type == 0x01
@assert tag.content == UInt8[0x00]
```

## Tree traversal

Because the package integrates with `AbstractTrees.jl`, constructed values can be walked naturally:

```julia
using ASN1
using AbstractTrees

bytes = UInt8[
    0x30, 0x06,       # SEQUENCE, length 6
    0x01, 0x01, 0x00, # BOOLEAN false
    0x01, 0x01, 0xFF  # BOOLEAN true
]

root = deserialize_ber(bytes)
for node in PreOrderDFS(root)
    println(node)
end
```

## Development

Run the test suite with:

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

Project documentation sources live under `docs/`, and the main package code lives under `src/`.
