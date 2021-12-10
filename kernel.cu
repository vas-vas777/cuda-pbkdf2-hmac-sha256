#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <cuda_runtime_api.h>
#include <random>
#include <string>
#include <bitset>
#include <iostream>


//#include <openssl/hmac.h>




__constant__ const uint32_t round_consts[64] = { 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2 };

//__device__ uint32_t pow_uint32_t(uint32_t a, uint32_t x)
//{
//    uint32_t res = 1;
//    for (auto i = 0; i < x; ++i)
//    {
//        res = a * res;
//    }
//    return res;
//}


__device__ uint32_t* to_binary_32bit(uint32_t number)
{
    uint32_t binary_str[32]{ 0 };
    
    int count = 31;
    while (number!=0)
    {
       
        binary_str[count] = number % 2;
        
        number /= 2;
        count--;
       
    }
    return binary_str;
   
}

__device__ uint32_t str_to_32bitnumber(uint32_t* str)
{
    uint32_t number1 = 0;
    for (auto i = 0; i < 32; ++i)
    {
        uint32_t number2 = 1;
        for (auto j = 0; j < (31 - i); ++j)
        {
            number2 *= 2;
        }
        number1 += str[i] * number2;
    }

    return number1;
}

__device__ uint32_t* and_strs_32bit(uint32_t* str1, uint32_t* str2)
{
    uint32_t result_str[32]{ 0 };
    for (auto i = 0; i < 32; ++i)
    {
        result_str[i] = str1[i] & str2[i];
    }
    return result_str;
    
}

__device__ uint32_t* inverse_str_32bit(uint32_t* str1)
{
    uint32_t result_str[32]{ 0 };
   
    for (auto i = 0; i < 32; ++i)
    {
        result_str[i] = !str1[i];
    }
    return result_str;
}

__device__ uint32_t* inverse_str_256bit(uint32_t* str1)
{
    uint32_t result_str[256]{ 0 };
    for (auto i = 0; i < 256; ++i)
    {
        result_str[i] = !str1[i];
    }
    return result_str;
    
}

__device__ uint32_t sum_strs_32bit(uint32_t str1[], uint32_t str2[])
{
    uint32_t number1 = 0;
    uint32_t number2 = 0;
    uint32_t res_number = 0;
    // int i = threadIdx.x ;
    for (int i = 0; i < 32; ++i)
        // if(i<32)
         //int i = blockIdx.x * blockDim.x + threadIdx.x;
    {
        uint32_t number3 = 1;
        for (auto j = 0; j < (31 - i); ++j)
        {
            number3 *= 2;
        }
        number1 += str1[i] * number3;
    }
    for (int i = 0; i < 32; ++i)
    {
        uint32_t number3 = 1;
        for (auto j = 0; j < (31 - i); ++j)
        {
            number3 *= 2;
        }
        number2 += str2[i] * number3;
    }
    res_number = (number1 + number2) % 4294967296;
   // __syncthreads();
    return res_number;
    // delete[]result_sum;
     //delete[]result_sum;
}

__device__ uint32_t* xor_strs_32bit(uint32_t* str1, uint32_t* str2)
{
    uint32_t result_xor[32]{ 0 };
    for (auto i = 0; i < 32; ++i)
    {
        result_xor[i] = str1[i] ^ str2[i];
    }
    return result_xor;
}

__device__ uint32_t* xor_strs_256bit(uint32_t* str1, uint32_t* str2)
{
    uint32_t result_xor[256]{ 0 };
    for (auto i = 0; i < 256; ++i)
    {
        result_xor[i] = str1[i] ^ str2[i];
    }
    return result_xor;
}

__device__ uint32_t rigth_rotate(uint32_t* str, unsigned int num)
{
    uint32_t number = 0;
    uint32_t rotated_str[32]{ 0 };
    memcpy(rotated_str, str, 4 * 32);
    number = str_to_32bitnumber(rotated_str);
    return (number >> num | number << (32 - num));
    
}

__device__ uint32_t rigth_shift(uint32_t* str, unsigned int num)
{
    
    uint32_t shifted_str[32]{ 0 };
   memcpy(shifted_str, str, 4 * 32);
    uint32_t number = str_to_32bitnumber(shifted_str);
    return number >> num;
       
}




__device__ void password_xor_with_IPAD(char* password,unsigned int length, uint32_t* output_str)
{
    uint32_t binary_str[512]{ 0 };
    
    uint32_t IPAD[] = { 0,0,1,1,0,1,1,0 };
    
    int i = threadIdx.x+blockIdx.x*blockDim.x;
    
    output_str[i] = binary_str[i] ^ IPAD[i % 8];
     __syncthreads();
  
  
    
}

__device__ void password_xor_with_OPAD(char* password, unsigned int length, uint32_t *output_str)
{
    uint32_t binary_str[512]{ 0 };
    uint32_t OPAD [] = { 0,1,0,1,1,1,0,0 };
   
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    output_str[i] = binary_str[i] ^ OPAD[i % 8];
    __syncthreads();
   
    
}

 __device__ void preparation_sha256_with_IPAD(uint32_t* password_xor_with_ipad, uint32_t*prev_hash, uint32_t *output_str)
{
     
     /*for (int i = threadIdx.x + blockIdx.x * blockDim.x; i < 1024; i += gridDim.x * blockDim.x)
     {
         output_str[i] = binary_str[i];
     }
     __syncthreads();*/
    
    // __syncthreads();
     
   // memcpy_1024bits(output_str, binary_str);
    // memcpy(output_str, binary_str, 4 * 1024);
     //return output_str;
}

__device__ void preparation_sha256_with_OPAD(uint32_t* password_xor_with_opad, uint32_t* prev_hash, uint32_t* output_str)
{
    //uint32_t binary_str[1024]{ 0 };
    
    
   /*for (int i = threadIdx.x + blockIdx.x * blockDim.x; i < 1024; i += gridDim.x * blockDim.x)
   {
       output_str[i] = binary_str[i];
   }
   __syncthreads();*/
    
    //memcpy_512bits(binary_str, password_xor_with_opad);
    //memcpy_256bits_prev_hash(binary_str, prev_hash);
    //// memcpy(binary_str, password_xor_with_opad, 4 * 512);
    //// memcpy(binary_str + 512, prev_hash, 4 * 256);
   
    //memcpy_1024bits(output_str, binary_str);

    
   
}

__device__ void main_loop_sha256(uint32_t* message, uint32_t* output_hash)
{
   
    uint32_t h0[32] { 0, 1, 1, 0,  1, 0, 1, 0,  0, 0, 0, 0,  1, 0, 0, 1,  1, 1, 1, 0,  0, 1, 1, 0,  0, 1, 1, 0,  0, 1, 1, 1 };
    uint32_t h1[32] { 1, 0, 1, 1,  1, 0, 1, 1,  0, 1, 1, 0,  0, 1, 1, 1,  1, 0, 1, 0,  1, 1, 1, 0,  1, 0, 0, 0,  0, 1, 0, 1 };
    uint32_t h2[32] { 0, 0, 1, 1,  1, 1, 0, 0,  0, 1, 1, 0,  1, 1, 1, 0,  1, 1, 1, 1,  0, 0, 1, 1,  0, 1, 1, 1,  0, 0, 1, 0 };
    uint32_t h3[32] { 1, 0, 1, 0,  0, 1, 0, 1,  0, 1, 0, 0,  1, 1, 1, 1,  1, 1, 1, 1,  0, 1, 0, 1,  0, 0, 1, 1,  1, 0, 1, 0 };
    uint32_t h4[32] { 0, 1, 0, 1,  0, 0, 0, 1,  0, 0, 0, 0,  1, 1, 1, 0,  0, 1, 0, 1,  0, 0, 1, 0,  0, 1, 1, 1,  1, 1, 1, 1 };
    uint32_t h5[32] { 1, 0, 0, 1,  1, 0, 1, 1,  0, 0, 0, 0,  0, 1, 0, 1,  0, 1, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 1, 0, 0 };
    uint32_t h6[32] { 0, 0, 0, 1,  1, 1, 1, 1,  1, 0, 0, 0,  0, 0, 1, 1,  1, 1, 0, 1,  1, 0, 0, 1,  1, 0, 1, 0,  1, 0, 1, 1 };
    uint32_t h7[32] { 0, 1, 0, 1,  1, 0, 1, 1,  1, 1, 1, 0,  0, 0, 0, 0,  1, 1, 0, 0,  1, 1, 0, 1,  0, 0, 0, 1,  1, 0, 0, 1 };
    uint32_t part_message1[512]{ 0 };/*{ 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1,
0,1,1,1,0,0,1,0, 0,1,1,0,1,1,0,0, 0,1,1,0,0,1,0,0, 1,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,1,0,1,1,0,0,0 };*/
    uint32_t part_message2[512]{ 0 };
    memcpy(part_message1, message, 4 * 512);
    memcpy(part_message2, message + 512, 4 * 512);
   
    int count = 1;//счётчик для 2ух итераций
   

   
    while (count < 3)
    {


        uint32_t S1[32]{ 0 };
        uint32_t ch[32]{ 0 };
        uint32_t temp1[32]{ 0 };
        uint32_t S0[32]{ 0 };
        uint32_t maj[32]{ 0 };
        uint32_t temp2[32]{ 0 };

        uint32_t a[32]{ 0 };
        uint32_t b[32]{ 0 };
        uint32_t c[32]{ 0 };
        uint32_t d[32]{ 0 };
        uint32_t e[32]{ 0 };
        uint32_t f[32]{ 0 };
        uint32_t g[32]{ 0 };
        uint32_t h[32]{ 0 };
        uint32_t extend_part_message1[64][32];
        /*for (auto i = 0; i < 64; ++i)
        {
            extend_part_message1[i] = new uint32_t[32]{ 0 };
        }*/

        if (count == 1)
        {
            for (auto i = 0; i < 16; ++i)
            {
                memcpy(extend_part_message1[i], part_message1 + (i * 32), 4 * 32);
                
            }
        }

        if (count == 2)
        {
            for (auto i = 0; i < 16; ++i)
            {
                memcpy(extend_part_message1[i], part_message2 + (i * 32), 4 * 32);
                
            }
        }

        /*printf("ext_message_before\n");
        for (auto i = 0; i < 64; ++i)
        {
            for (auto j = 0; j < 32; ++j)
            {
                printf("%d", extend_part_message1[i][j]);
            }
            printf("\n");
        }
        printf("\n");*/
        
        for (auto i = 16; i < 64; ++i)
        {
            uint32_t s0[32]{ 0 };
            uint32_t s1[32]{ 0 };
            uint32_t sum_ext1_2_s0_s1 = 0;


            memcpy(s0, xor_strs_32bit(xor_strs_32bit(to_binary_32bit(rigth_rotate(extend_part_message1[i - 15], 7)),
                to_binary_32bit(rigth_rotate(extend_part_message1[i - 15], 18))),
                to_binary_32bit(rigth_shift(extend_part_message1[i - 15], 3))), 4 * 32);



            memcpy(s1, xor_strs_32bit(xor_strs_32bit(to_binary_32bit(rigth_rotate(extend_part_message1[i - 2], 17)),
                to_binary_32bit(rigth_rotate(extend_part_message1[i - 2], 19))),
                to_binary_32bit(rigth_shift(extend_part_message1[i - 2], 10))), 4 * 32);


            sum_ext1_2_s0_s1 = (sum_strs_32bit(extend_part_message1[i - 16], s0) + sum_strs_32bit(extend_part_message1[i - 7], s1)) % 4294967296;


            memcpy(extend_part_message1[i], to_binary_32bit(sum_ext1_2_s0_s1), 4 * 32);

        }
        /*printf("ext_message_after\n");
        for (auto i = 0; i < 64; ++i)
        {
            for (auto j = 0; j < 32; ++j)
            {
                printf("%d", extend_part_message1[i][j]);
            }
            printf("\n");
        }
        printf("\n");*/

        memcpy(a, h0, 4 * 32);
        memcpy(b, h1, 4 * 32);
        memcpy(c, h2, 4 * 32);
        memcpy(d, h3, 4 * 32);
        memcpy(e, h4, 4 * 32);
        memcpy(f, h5, 4 * 32);
        memcpy(g, h6, 4 * 32);
        memcpy(h, h7, 4 * 32);
#pragma unroll 64
        for (auto i = 0; i < 64; ++i)
        {

            memcpy(S1, xor_strs_32bit(xor_strs_32bit(to_binary_32bit(rigth_rotate(e, 6)), to_binary_32bit(rigth_rotate(e, 11))),
                to_binary_32bit(rigth_rotate(e, 25))), 4 * 32);
            memcpy(ch, xor_strs_32bit(and_strs_32bit(e, f), and_strs_32bit(inverse_str_32bit(e), g)), 4 * 32);

            memcpy(temp1, to_binary_32bit((sum_strs_32bit(h, S1) + sum_strs_32bit(ch, extend_part_message1[i]) + round_consts[i]) % 4294967296), 4 * 32);

            memcpy(S0, xor_strs_32bit(xor_strs_32bit(to_binary_32bit(rigth_rotate(a, 2)), to_binary_32bit(rigth_rotate(a, 13))),
                to_binary_32bit(rigth_rotate(a, 22))), 4 * 32);

            memcpy(maj, xor_strs_32bit(xor_strs_32bit(and_strs_32bit(a, b), and_strs_32bit(a, c)),
                and_strs_32bit(b, c)), 4 * 32);

            memcpy(temp2, to_binary_32bit(sum_strs_32bit(S0, maj)), 4 * 32);

            memcpy(h, g, 4 * 32);

            memcpy(g, f, 4 * 32);

            memcpy(f, e, 4 * 32);
            memcpy(e, to_binary_32bit(sum_strs_32bit(d, temp1)), 4 * 32);

            memcpy(d, c, 4 * 32);
            memcpy(c, b, 4 * 32);
            memcpy(b, a, 4 * 32);

            memcpy(a, to_binary_32bit(sum_strs_32bit(temp1, temp2)), 4 * 32);
            // __syncthreads();
           //  __syncthreads();
        }
        count++;

        memcpy(h0, to_binary_32bit(sum_strs_32bit(h0, a)), 4 * 32);
        memcpy(h1, to_binary_32bit(sum_strs_32bit(h1, b)), 4 * 32);
        memcpy(h2, to_binary_32bit(sum_strs_32bit(h2, c)), 4 * 32);
        memcpy(h3, to_binary_32bit(sum_strs_32bit(h3, d)), 4 * 32);
        memcpy(h4, to_binary_32bit(sum_strs_32bit(h4, e)), 4 * 32);
        memcpy(h5, to_binary_32bit(sum_strs_32bit(h5, f)), 4 * 32);
        memcpy(h6, to_binary_32bit(sum_strs_32bit(h6, g)), 4 * 32);
        memcpy(h7, to_binary_32bit(sum_strs_32bit(h7, h)), 4 * 32);

    }
    
    uint32_t hash[256]{ 0 };
    memcpy(hash, h0, 4*32);
    memcpy(hash + 32, h1, 4*32);
    memcpy(hash + 64, h2, 4*32);
    memcpy(hash + 96, h3, 4*32);
    memcpy(hash + 128, h4, 4*32);
    memcpy(hash + 160, h5, 4*32);
    memcpy(hash + 192, h6, 4*32);
    memcpy(hash + 224, h7, 4*32);
    
    memcpy(output_hash, hash, 4 * 256);
  
}



__device__ void hmac_sha256(int c, uint32_t* pass_xor_ipad, uint32_t* pass_xor_opad, uint32_t* prev_hash1)
{
    
    //for (auto i = 0; i < 1; ++i)
    //{
    //   //printf("%d\n", i);
    //    preparation_sha256_with_IPAD(pass_xor_ipad, prev_hash1, message);
    //   // 
    //    preparation_sha256_with_OPAD(pass_xor_opad, prev_hash1, message);
    //   
    //   // memcpy(prev_hash_hmac, xor_strs_256bit(prev_hash_hmac, prev_hash1), 4 * 256);
    //}
   
    //return message;
}

__global__ void password_xor_with_ipad_opad(char* password, unsigned int length, uint32_t* pass_xor_ipad, uint32_t* pass_xor_opad)
{
    password_xor_with_IPAD(password, length, pass_xor_ipad);
    password_xor_with_OPAD(password, length, pass_xor_opad);
}

__global__ void pbkdf2_hmac_sha256(unsigned int c, uint32_t* pass_xor_ipad, uint32_t* pass_xor_opad,uint32_t* salt, uint32_t* pbkdf2_hash)
{
   // int i = threadIdx.x;
    //preparation_sha256_with_IPAD(pass_xor_ipad, salt, pbkdf2_hash);
    uint32_t message[1024]{ 0 };
    uint32_t prev_hash_hmac[256]{ 0 };
   // int i = 0;
    //memcpy(pbkdf2_hash, hmac_sha256(c, pass_xor_ipad, pass_xor_opad, salt), 4 * 256);
    for (auto j = 0; j < c; ++j)
    {
        //printf("%d\n", j);
        for (int i = threadIdx.x + blockIdx.x * blockDim.x; i < 512; i += gridDim.x * blockDim.x)
        {
            //  __syncthreads();
            message[i] = pass_xor_ipad[i];
            __syncthreads();
        }

        for (int j = threadIdx.x + blockIdx.x * blockDim.x; j < 256; j += gridDim.x * blockDim.x)
        {

           message[j + 512] = salt[j];
            __syncthreads();
        }
        // __syncthreads();
        message[768] = 1;
        message[1014] = 1;
        message[1015] = 1;

        main_loop_sha256(message, salt);
        __syncthreads();

        for (int s = threadIdx.x + blockIdx.x * blockDim.x; s < 512; s += gridDim.x * blockDim.x)
        {
            // __syncthreads();
            message[s] = pass_xor_opad[s];
            __syncthreads();
        }

        for (int d = threadIdx.x + blockIdx.x * blockDim.x; d < 256; d += gridDim.x * blockDim.x)
        {
            //__syncthreads();
            message[d + 512] = salt[d];
            __syncthreads();
        }

        message[768] = 1;
        message[1014] = 1;
        message[1015] = 1;
        __syncthreads();

      
      
        main_loop_sha256(message, salt);
        __syncthreads();
      

        for (int i = threadIdx.x + blockIdx.x * blockDim.x; i < 256; i += gridDim.x * blockDim.x)
        {
              __syncthreads();
            prev_hash_hmac[i] = prev_hash_hmac[i] ^ salt[i];
            __syncthreads();
        }
        __syncthreads();

        // __syncthreads();
    }
    for (int i = threadIdx.x + blockIdx.x * blockDim.x; i < 256; i += gridDim.x * blockDim.x)
    {
        //  __syncthreads();
        pbkdf2_hash[i] = prev_hash_hmac[i];
        __syncthreads();
    }

}


//__device__ void pbkdf2_hmac_sha256()
//{
//    // 
//    // uint32_t *hash = new uint32_t[256]{ 0 };
//    // uint32_t *salt = new uint32_t[256]{ 0 };
//    // uint32_t *prev_hash = new uint32_t[256]{ 0 };
//    // //uint32_t* temp = new uint32_t[256]{ 0 };
//
//    // uint32_t password_xor_with_ipad[512]{ 0 };
//    // uint32_t password_xor_with_opad[512]{ 0 };
//
//    // memcpy(password_xor_with_ipad, password_xor_with_IPAD(password, length), 4 * 512);
//    // memcpy(password_xor_with_opad, password_xor_with_OPAD(password, length), 4 * 512);
//    //// int index = threadIdx.x + blockIdx.x*blockDim.x;
//    // uint32_t dklen = 256;
//    // uint32_t len = dklen / 256;
//    // uint32_t r = dklen - (len - 1) * 256;
//    // int index = threadIdx.x;
//    //
//    // //for (auto index = 0; index < len; ++index)
//    // while (index < len)
//    // {
//    //     salt[255] = index;
//    //     memcpy(prev_hash, salt, 4 * 256);
//    //     uint32_t temp_hash[256]{ 0 };
//    //     for (auto j = 0; j < c; ++j)
//    //     {
//    //         memcpy(prev_hash, hmac_sha256(prev_hash, password_xor_with_ipad, password_xor_with_opad), 4 * 256);
//    //         memcpy(temp_hash, xor_strs(temp_hash, prev_hash,256), 4 * 256);
//    //     }
//    //    
//    //     memcpy(hash + index * 256, temp_hash, 4 * 256);
//    // }
//    // delete[] salt;
//    // delete[] prev_hash;
//    // delete[] password_xor_with_ipad;
//    // delete[] password_xor_with_opad;
//    // return hash;
//
//}

uint32_t* random_salt(size_t Nbits)
{
    std::random_device rd;  //Will be used to obtain a seed for the random number engine
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> int1(0, 1);
    uint32_t* str = new uint32_t[Nbits];
    //str.reserve(Nbits);
    for (size_t i = 0; i < Nbits; i++)
    {
        str[i] = int1(gen) ? 1 : 0;
    }
    return str;
};



int main()
{

    //std::string password = "1234";
    unsigned int len_hash_pbkdf2 = 1;
    //    uint32_t* pbkdf2_hash = new uint32_t[len_hash_pbkdf2 * 256];
    uint32_t* salt = new uint32_t[256]{ 0 };
    //memcpy(salt, random_salt(254), 4 * 254);



    uint32_t* password_xor_with_ipad = new uint32_t[512]{ 0 };
    uint32_t* password_xor_with_opad = new uint32_t[512]{ 0 };
    uint32_t* pbkdf2_hash = new uint32_t[len_hash_pbkdf2 * 1024]{ 0 };
    uint32_t* dev_password_xor_with_ipad;
    uint32_t* dev_password_xor_with_opad;
    uint32_t* dev_pbkdf2_hash;
    uint32_t* dev_salt;


    cudaError_t cudaStatus;
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }


    cudaStatus = cudaMalloc((void**)&dev_password_xor_with_ipad, 512 * sizeof(uint32_t));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        //goto Error;
    }
    cudaStatus = cudaMemcpy(dev_password_xor_with_ipad, password_xor_with_ipad, 512 * sizeof(uint32_t), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }
    cudaStatus = cudaMalloc((void**)&dev_password_xor_with_opad, 512 * sizeof(uint32_t));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        //goto Error;
    }
    cudaStatus = cudaMemcpy(dev_password_xor_with_opad, password_xor_with_opad, 512 * sizeof(uint32_t), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }



    password_xor_with_ipad_opad << <16, 32>> > ("1234", 4, dev_password_xor_with_ipad, dev_password_xor_with_opad);



    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }

    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel %s!\n", cudaStatus, cudaGetErrorString(cudaStatus));
        goto Error;
    }

    cudaStatus = cudaMemcpy(password_xor_with_ipad, dev_password_xor_with_ipad, 512 * sizeof(uint32_t), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(password_xor_with_opad, dev_password_xor_with_opad, 512 * sizeof(uint32_t), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }
    for (auto i = 0; i < 512; ++i)
    {
        std::cout << password_xor_with_ipad[i];
    }
    std::cout << std::endl;

    for (auto i = 0; i < 512; ++i)
    {
        std::cout << password_xor_with_opad[i];
    }
    std::cout << std::endl;

    cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
        return 1;
    }
    //---------------------------------------------------------------------------------------------------------
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_pbkdf2_hash, len_hash_pbkdf2 * 1024 * sizeof(uint32_t));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(dev_pbkdf2_hash, pbkdf2_hash, len_hash_pbkdf2 * 1024 * sizeof(uint32_t), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_salt, 256 * sizeof(uint32_t));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(dev_salt, salt, 256 * sizeof(uint32_t), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_password_xor_with_ipad, 512 * sizeof(uint32_t));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }
    cudaStatus = cudaMemcpy(dev_password_xor_with_ipad, password_xor_with_ipad, 512 * sizeof(uint32_t), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }
    cudaStatus = cudaMalloc((void**)&dev_password_xor_with_opad, 512 * sizeof(uint32_t));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }
    cudaStatus = cudaMemcpy(dev_password_xor_with_opad, password_xor_with_opad, 512 * sizeof(uint32_t), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    pbkdf2_hmac_sha256 << <1, 1024 >> > (3,  dev_password_xor_with_ipad, dev_password_xor_with_opad, dev_salt, dev_pbkdf2_hash);

    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }

    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel %s!\n", cudaStatus, cudaGetErrorString(cudaStatus));
        goto Error;
    }

    cudaStatus = cudaMemcpy(pbkdf2_hash, dev_pbkdf2_hash, len_hash_pbkdf2 * 1024 * sizeof(uint32_t), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    //main_loop_sha256(message_for_sha256, hash);
    for (auto i = 0; i < 1024; ++i)
    {
        std::cout << pbkdf2_hash[i];
    }
    std::cout << std::endl;

    cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
        return 1;

        //------------------------------------------------------------------------------------------------------------


                // Copy output vector from GPU buffer to host memory.






        return 0;
    Error:
        cudaFree(dev_password_xor_with_ipad);
        cudaFree(dev_password_xor_with_opad);
        //cudaFree(dev_pbkdf2_hash);
        //cudaFree(dev_salt);
        /*cudaFree(device_hash);
        cudaFree(hash);
        cudaFree(device_message_1024bits);

        cudaFree(dev_b);*/
    }
}


// Helper function for using CUDA to add vectors in parallel.

