//
//  BrotliCommon.hpp
//  Brotli
//
//  Created by Evgenij Lutz on 10.03.26.
//

#pragma once

#include <brotli/libbrotlicommon.h>
#include <BrotliCommon/Common.hpp>


typedef void (* BrotliCallback)(void* fn_nullable userInfo);
typedef void (* BrotliProgressCallback)(void* fn_nullable userInfo, float progress);
