//
//  BrotliCompressor.hpp
//  Brotli
//
//  Created by Evgenij Lutz on 10.03.26.
//

#pragma once

#include <brotli/encode.h>
#include <BrotliCommon/BrotliCommon.hpp>


class BrotliCompressor final {
private:
    std::atomic<size_t> _referenceCounter;
    
    BrotliEncoderState* fn_nonnull _state;
    
    FN_FRIEND_SWIFT_INTERFACE(BrotliCompressor)
    
    BrotliCompressor(BrotliEncoderState* fn_nonnull state);
    ~BrotliCompressor();
    
public:
    static BrotliCompressor* fn_nonnull create() SWIFT_NAME(init()) SWIFT_RETURNS_RETAINED;
    
    void test();
    
    void compress(void* fn_nullable userInfo, BrotliProgressCallback fn_nullable progressCallback);
}
FN_SWIFT_INTERFACE(BrotliCompressor);
