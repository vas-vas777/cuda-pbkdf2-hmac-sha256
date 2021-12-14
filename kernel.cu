﻿#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "cuda_runtime_api.h"
#include <cuda.h>
#include <random>
#include <string>
#include <bitset>
#include <iostream>
#include <fstream>


#define count_passwords 500
#define length_passwords 64



__constant__ const uint32_t round_consts[64] = { 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2 };






__device__ uint32_t* to_binary_32bit(uint32_t number, uint32_t* binary_str)
{
    
  
   
    int count = 31;
    while (number != 0)
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

//__device__ uint32_t* and_strs_32bit(uint32_t* str1, uint32_t* str2, uint32_t* and_result)
//{
//   
//   
//   
//    for (auto i = 0; i < 32; ++i)
//    {
//       /* atomicAnd(&and_result[i], str1[i]);
//        atomicAnd(&and_result[i], str2[i]);*/
//       // __syncthreads();
//      and_result[i] = str1[i] & str2[i];
//    }
//    
//   return and_result;
//   
//}
//
//__device__ uint32_t* inverse_str_32bit(uint32_t* str1, uint32_t* inverse_result)
//{
//    for (auto i = 0; i < 32; ++i)
//    {
//        inverse_result[i] = !(str1[i]);
//    }
//   return inverse_result;
//   
//}



__device__ uint32_t sum_strs_32bit(uint32_t *str1, uint32_t *str2)
{
    uint32_t number1[1]{ 0 };
    uint32_t number2[1]{ 0 };
   
    uint32_t res_number = 0;
    for (auto i = 0; i < 32; ++i)
    {
        atomicAdd(&number1[0], str1[i] * __powf(2, (31 - i)));
        atomicAdd(&number2[0], str2[i] * __powf(2, (31 - i)));
       // __syncthreads();
        
    }
    res_number = ((number1[0]) + (number2[0])) % 4294967296;
    return res_number;
   
}


__device__ void xor_strs(uint32_t* str1, uint32_t* str2, unsigned int length, uint32_t* result_xor, uint32_t* str3)
{
   
    for (auto i = 0; i <length; ++i)   
    {
        /*atomicXor(&(result_xor[i]), str1[i]);
        atomicXor(&(result_xor[i]), str2[i]);
        atomicXor(&(result_xor[i]), str3[i]);
        __syncthreads();*/
        result_xor[i] = str1[i] ^ str2[i];
        result_xor[i] = result_xor[i] ^ str3[i];
    }
    
   
  // return result_xor;
   // delete[] result_xor;
}

//__device__ uint32_t* rigth_rotate(uint32_t* str, unsigned int num,uint32_t* result_right_rotate)
//{
//    uint32_t number = 0;
//    number = str_to_32bitnumber(str);
//    number = ((number >> num) | (number << (32 - num)));
//   
//    to_binary_32bit(number, result_right_rotate);
//    return result_right_rotate;
//   
//
//}
//
//__device__ uint32_t* rigth_shift(uint32_t* str, unsigned int num, uint32_t* result_right_shift)
//{
//
//   
//   
//    uint32_t number = str_to_32bitnumber(str);
//   
//    to_binary_32bit(number >> num, result_right_shift);
//    return result_right_shift;
//
//}



__device__ void password_xor_with_IPAD(uint32_t* password,size_t length, uint32_t* output_str)
{
    uint32_t binary_str[512]{ 0 };
    memcpy(binary_str, password, sizeof(uint32_t) * 64);
    
    uint32_t IPAD[] = { 0,0,1,1,0,1,1,0 };

   // xor_strs(binary_str)
    
    for (int i = 0; i < 512; ++i)
    {
        output_str[i] = binary_str[i] ^ IPAD[i % 8];
        __syncthreads();
    }
  //  __syncthreads();
    
}

__device__ void password_xor_with_OPAD(uint32_t* password, size_t length, uint32_t *output_str)
{
    uint32_t binary_str[512]{ 0 };
    uint32_t OPAD[] = { 0,1,0,1,1,1,0,0 };
    memcpy(binary_str, password, sizeof(uint32_t) * 64);
   
   // __syncthreads();
    for (int k = 0; k < 512; ++k)
    {
        output_str[k] = binary_str[k] ^ OPAD[k % 8];
        /*atomicXor(&(output_str[k]), binary_str[k]);
        atomicXor(&(output_str[k]), OPAD[k % 8]);*/
        __syncthreads();
    }
   // __syncthreads();
}

 __device__ void preparation_sha256_with_IPAD(uint32_t* password_xor_with_ipad, uint32_t*prev_hash, uint32_t *output_str)
{
     uint32_t message[1024]{ 0 };
     //uint32_t prev_hash_hmac[256]{ 0 };
     for (int k = 0; k < 512; ++k)
     {
         //  __syncthreads();
         message[k] = password_xor_with_ipad[k];
         __syncthreads();
     }

     for (int k = 0; k < 256; ++k)
     {
         message[k + 512] = prev_hash[k];
         __syncthreads();
     }
     // __syncthreads();
     message[768] = 1;
     message[1014] = 1;
     message[1015] = 1;
     for (int k = 0; k < 1024; ++k)
     {
         output_str[k] = message[k];
         __syncthreads();
     }
}

__device__ void preparation_sha256_with_OPAD(uint32_t* password_xor_with_opad, uint32_t* prev_hash, uint32_t* output_str)
{
    uint32_t message[1024]{ 0 };
    for (int k = 0; k < 512; ++k)
    {
        // __syncthreads();
        message[k] = password_xor_with_opad[k];
        __syncthreads();
    }

    for (int k = 0; k < 256; ++k)
    {
        //__syncthreads();
        message[k + 512] = prev_hash[k];
        __syncthreads();
    }

    message[768] = 1;
    message[1014] = 1;
    message[1015] = 1;
    for (int j = 0; j < 1024; ++j)
    {

        output_str[j] = message[j];
        __syncthreads();
    }
    
   
}

__device__ void main_loop_sha256(uint32_t* message, uint32_t* output_hash)
{

    uint32_t h0[32]{ 0, 1, 1, 0,  1, 0, 1, 0,  0, 0, 0, 0,  1, 0, 0, 1,  1, 1, 1, 0,  0, 1, 1, 0,  0, 1, 1, 0,  0, 1, 1, 1 };
    uint32_t h1[32]{ 1, 0, 1, 1,  1, 0, 1, 1,  0, 1, 1, 0,  0, 1, 1, 1,  1, 0, 1, 0,  1, 1, 1, 0,  1, 0, 0, 0,  0, 1, 0, 1 };
    uint32_t h2[32]{ 0, 0, 1, 1,  1, 1, 0, 0,  0, 1, 1, 0,  1, 1, 1, 0,  1, 1, 1, 1,  0, 0, 1, 1,  0, 1, 1, 1,  0, 0, 1, 0 };
    uint32_t h3[32]{ 1, 0, 1, 0,  0, 1, 0, 1,  0, 1, 0, 0,  1, 1, 1, 1,  1, 1, 1, 1,  0, 1, 0, 1,  0, 0, 1, 1,  1, 0, 1, 0 };
    uint32_t h4[32]{ 0, 1, 0, 1,  0, 0, 0, 1,  0, 0, 0, 0,  1, 1, 1, 0,  0, 1, 0, 1,  0, 0, 1, 0,  0, 1, 1, 1,  1, 1, 1, 1 };
    uint32_t h5[32]{ 1, 0, 0, 1,  1, 0, 1, 1,  0, 0, 0, 0,  0, 1, 0, 1,  0, 1, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 1, 0, 0 };
    uint32_t h6[32]{ 0, 0, 0, 1,  1, 1, 1, 1,  1, 0, 0, 0,  0, 0, 1, 1,  1, 1, 0, 1,  1, 0, 0, 1,  1, 0, 1, 0,  1, 0, 1, 1 };
    uint32_t h7[32]{ 0, 1, 0, 1,  1, 0, 1, 1,  1, 1, 1, 0,  0, 0, 0, 0,  1, 1, 0, 0,  1, 1, 0, 1,  0, 0, 0, 1,  1, 0, 0, 1 };
       
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


      //  uint32_t S1[32]{ 0 };
       // uint32_t ch[32]{ 0 };
        uint32_t temp1[32]{ 0 };
      //  uint32_t S0[32]{ 0 };
     //   uint32_t maj[32]{ 0 };
        uint32_t temp2[32]{ 0 };

        uint32_t a[32]{ 0 };
        uint32_t b[32]{ 0 };
        uint32_t c[32]{ 0 };
        uint32_t d[32]{ 0 };
        uint32_t e[32]{ 0 };
        uint32_t f[32]{ 0 };
        uint32_t g[32]{ 0 };
        uint32_t h[32]{ 0 };
        uint32_t extend_part_message1[64][32]{ 0 };
        



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
       /* printf("extend-message-before\n");
        for (auto i = 0; i < 64; ++i)
        {
            for (auto j = 0; j < 32; ++j)
            {
                printf("%u", extend_part_message1[i][j]);
            }
            printf("\n");
        }*/

        for (auto i = 16; i < 64; ++i)
        {
            for (int j = 0; j < 32; j++)
            {
                extend_part_message1[i][j] = extend_part_message1[i - 16][j] + extend_part_message1[i - 7][j] +
                    ((extend_part_message1[i - 15][(j + 25) % 32] + extend_part_message1[i - 15][(j + 14) % 32] + (j < 3 ? 0 : extend_part_message1[i - 15][(j + 29) % 32])) % 2) +
                    ((extend_part_message1[i - 2][(j + 15) % 32] + extend_part_message1[i - 2][(j + 13) % 32] + (j < 10 ? 0 : extend_part_message1[i - 2][(j + 22) % 32])) % 2);
            }
            for (int j = 31; j > 0; j--)
            {
                while (extend_part_message1[i][j] >= 2) {
                    extend_part_message1[i][j] -= 2;
                    extend_part_message1[i][j - 1]++;
                }
            }
            extend_part_message1[i][0] = extend_part_message1[i][0] % 2;
           /* uint32_t s0[32]{ 0 };
            uint32_t s1[32]{ 0 };
            uint32_t sum_ext1_2_s0_s1 = 0;
            uint32_t result_xor1[32]{ 0 };
            uint32_t result_xor2[32]{ 0 };
            uint32_t result_right_rotate1[32]{ 0 };
            uint32_t result_right_rotate2[32]{ 0 };
            uint32_t result_right_rotate3[32]{ 0 };
            uint32_t result_right_rotate4[32]{ 0 };
            uint32_t result_right_shift1[32]{ 0 };
            uint32_t result_right_shift2[32]{ 0 };

            rigth_rotate(extend_part_message1[i - 15], 7, result_right_rotate1);
            rigth_rotate(extend_part_message1[i - 15], 18, result_right_rotate2);

            rigth_shift(extend_part_message1[i - 15], 3, result_right_shift1);
            
            xor_strs(result_right_rotate1, result_right_rotate2, 32,
                result_xor1, result_right_shift1);
            memcpy(s0, result_xor1, 4 * 32);

           
            rigth_rotate(extend_part_message1[i - 2], 17, result_right_rotate3);
            rigth_rotate(extend_part_message1[i - 2], 19, result_right_rotate4);
            rigth_shift(extend_part_message1[i - 2], 10, result_right_shift2);

            xor_strs(result_right_rotate3, result_right_rotate4, 32,
                result_xor2, result_right_shift2);
            memcpy(s1, result_xor2, 4 * 32);

            


            sum_ext1_2_s0_s1 = (sum_strs_32bit(extend_part_message1[i - 16], s0) + sum_strs_32bit(extend_part_message1[i - 7], s1)) % 4294967296;

            to_binary_32bit(sum_ext1_2_s0_s1, extend_part_message1[i]);*/
          

        }
       
        /*printf("extend-message-after\n");
        for (auto i = 0; i < 64; ++i)
        {
            for (auto j = 0; j < 32; ++j)
            {
                printf("%u", extend_part_message1[i][j]);
            }
            printf("\n");
        }*/
        memcpy(a, h0, 4 * 32);
        memcpy(b, h1, 4 * 32);
        memcpy(c, h2, 4 * 32);
        memcpy(d, h3, 4 * 32);
        memcpy(e, h4, 4 * 32);
        memcpy(f, h5, 4 * 32);
        memcpy(g, h6, 4 * 32);
        memcpy(h, h7, 4 * 32);

        for (auto i = 0; i < 64; ++i)
        {
            /*uint32_t res_and1[32]{ 0 };
            uint32_t res_and2[32]{ 0 };
            uint32_t res_and3[32]{ 0 };
            uint32_t res_and4[32]{ 0 };
            uint32_t res_and5[32]{ 0 };

            uint32_t res_inv[32]{ 0 };
            uint32_t res_xor1[32]{ 0 };
            uint32_t res_xor2[32]{ 0 };
            uint32_t temp_res_xor[32]{ 0 };
            uint32_t res_xor3[32]{ 0 };
            uint32_t res_xor4[32]{ 0 };

            uint32_t res_right_rotate1[32]{ 0 };
            uint32_t res_right_rotate2[32]{ 0 };
            uint32_t res_right_rotate3[32]{ 0 };
            uint32_t res_right_rotate4[32]{ 0 };
            uint32_t res_right_rotate5[32]{ 0 };
            uint32_t res_right_rotate6[32]{ 0 };*/

           /* rigth_rotate(e, 6, res_right_rotate1);
            rigth_rotate(e, 11, res_right_rotate2);
            rigth_rotate(e, 25, res_right_rotate3);
            xor_strs(res_right_rotate1, res_right_rotate2, 32, res_xor1, res_right_rotate3);
            memcpy(S1, res_xor1, 4 * 32);*/


            /*memcpy(S1, xor_strs(xor_strs(to_binary_32bit(rigth_rotate(e, 6)), to_binary_32bit(rigth_rotate(e, 11)), 32),
                to_binary_32bit(rigth_rotate(e, 25)), 32), 4 * 32);*/
            /*and_strs_32bit(e, f, res_and1);
            inverse_str_32bit(e, res_inv);
            and_strs_32bit(res_inv, g, res_and2);
            xor_strs(res_and1, res_and2, 32, res_xor2,temp_res_xor);
            memcpy(ch, res_xor2, 4 * 32);

            uint32_t to_binary_32bit0[32]{ 0 };*/
            //memcpy(ch, xor_strs(and_strs_32bit(e, f), and_strs_32bit(inverse_str_32bit(e), g), 32), 4 * 32);
           /* to_binary_32bit(((sum_strs_32bit(h, S1) + sum_strs_32bit(ch, extend_part_message1[i]) + round_consts[i]) % 4294967296), to_binary_32bit0);
            memcpy(temp1, to_binary_32bit0,4*32);
            rigth_rotate(a, 2, res_right_rotate4);
            rigth_rotate(a, 13, res_right_rotate5);
            rigth_rotate(a, 22, res_right_rotate6);
            xor_strs(res_right_rotate4,res_right_rotate5 , 32, res_xor3, res_right_rotate6);
            memcpy(S0, res_xor3, 4 * 32);*/

           // memcpy(S0, xor_strs(xor_strs(to_binary_32bit(rigth_rotate(a, 2)), to_binary_32bit(rigth_rotate(a, 13)), 32),
           //     to_binary_32bit(rigth_rotate(a, 22)), 32), 4 * 32);

           // memcpy(maj, xor_strs(xor_strs(and_strs_32bit(a, b), and_strs_32bit(a, c), 32),
            //    and_strs_32bit(b, c), 32), 4 * 32);
            /*and_strs_32bit(a, b, res_and3);
            and_strs_32bit(a, c, res_and4);
            and_strs_32bit(b, c, res_and5);
            xor_strs(res_and3, res_and4, 32, res_xor4, res_and5);
            memcpy(maj, res_xor4, 4 * 32);*/

            uint32_t round_cnst[32]{ 0 };
            to_binary_32bit(round_consts[i], round_cnst);
           
            for (int j = 0; j < 32; j++)
            {
                temp2[j] = ((a[(j + 30) % 32] + a[(j + 19) % 32] + a[(j + 10) % 32]) % 2) +
                    (((b[j] == 1 && a[j] == 1 ? 1 : 0) + (c[j] == 1 && a[j] == 1 ? 1 : 0) + (c[j] == 1 && b[j] == 1 ? 1 : 0)) % 2);

                temp1[j] = h[j] +
                    ((e[(j + 26) % 32] + e[(j + 21) % 32] + e[(j + 7) % 32]) % 2) +
                    (((f[j] == 1 && e[j] == 1 ? 1 : 0) + (e[j] == 0 && g[j] == 1 ? 1 : 0)) % 2) +
                    extend_part_message1[i][j] +
                    round_cnst[j];
            }

            for (int j = 31; j > 0; j--)
            {
                while (temp2[j] >= 2) {
                    temp2[j] -= 2;
                    temp2[j - 1]++;
                }

                while (temp1[j] >= 2) {
                    temp1[j] -= 2;
                    temp1[j - 1]++;
                }
            }
            temp2[0] = temp2[0] % 2;
            temp1[0] = temp1[0] % 2;


        //    uint32_t to_binary_32bit1[32]{ 0 };
            uint32_t to_binary_32bit2[32]{ 0 };
            uint32_t to_binary_32bit3[32]{ 0 };
           

           /* to_binary_32bit(sum_strs_32bit(S0, maj), to_binary_32bit1);
            memcpy(temp2, to_binary_32bit1, 4 * 32);*/
            

            memcpy(h, g, 4 * 32);
           

            memcpy(g, f, 4 * 32);
            


            memcpy(f, e, 4 * 32);
          

            to_binary_32bit(sum_strs_32bit(d, temp1), to_binary_32bit2);
            memcpy(e, to_binary_32bit2, 4 * 32);
           

            memcpy(d, c, 4 * 32);
           
            memcpy(c, b, 4 * 32);
            
            memcpy(b, a, 4 * 32);
           

            to_binary_32bit(sum_strs_32bit(temp1, temp2),to_binary_32bit3);
            memcpy(a, to_binary_32bit3, 4 * 32);        

        }
         
        count++;

        uint32_t to_binary_32bith0[32]{ 0 };
        uint32_t to_binary_32bith1[32]{ 0 };
        uint32_t to_binary_32bith2[32]{ 0 };
        uint32_t to_binary_32bith3[32]{ 0 };
        uint32_t to_binary_32bith4[32]{ 0 };
        uint32_t to_binary_32bith5[32]{ 0 };
        uint32_t to_binary_32bith6[32]{ 0 };
        uint32_t to_binary_32bith7[32]{ 0 };

        to_binary_32bit(sum_strs_32bit(h0, a), to_binary_32bith0);
        memcpy(h0, to_binary_32bith0, 4 * 32);
        to_binary_32bit(sum_strs_32bit(h1, b), to_binary_32bith1);
        memcpy(h1, to_binary_32bith1, 4 * 32);
        to_binary_32bit(sum_strs_32bit(h2, c), to_binary_32bith2);
        memcpy(h2, to_binary_32bith2, 4 * 32);
        to_binary_32bit(sum_strs_32bit(h3, d), to_binary_32bith3);
        memcpy(h3, to_binary_32bith3, 4 * 32);
        to_binary_32bit(sum_strs_32bit(h4, e), to_binary_32bith4);
        memcpy(h4, to_binary_32bith4, 4 * 32);
        to_binary_32bit(sum_strs_32bit(h5, f), to_binary_32bith5);
        memcpy(h5, to_binary_32bith5, 4 * 32);
        to_binary_32bit(sum_strs_32bit(h6, g), to_binary_32bith6);
        memcpy(h6, to_binary_32bith6, 4 * 32);
        to_binary_32bit(sum_strs_32bit(h7, h), to_binary_32bith7);
        memcpy(h7, to_binary_32bith7, 4 * 32);
       
    }

    uint32_t *hash=new uint32_t[256]{ 0 };
    memcpy(hash, h0, 4 * 32);
    memcpy(hash + 32, h1, 4 * 32);
    memcpy(hash + 64, h2, 4 * 32);
    memcpy(hash + 96, h3, 4 * 32);
    memcpy(hash + 128, h4, 4 * 32);
    memcpy(hash + 160, h5, 4 * 32);
    memcpy(hash + 192, h6, 4 * 32);
    memcpy(hash + 224, h7, 4 * 32);
    memcpy(output_hash, hash, 4 * 256);
    /*printf("\n");
    for (auto i = 0; i < 256; ++i)
    {
        printf("%u", output_hash[i]);
    }
    printf("\n");*/

}




//__device__ void hmac_sha256(int c, uint32_t* pass_xor_ipad, uint32_t* pass_xor_opad, uint32_t* prev_hash1)
//{
//    
//    //for (auto i = 0; i < 1; ++i)
//    //{
//    //   //printf("%d\n", i);
//    //    preparation_sha256_with_IPAD(pass_xor_ipad, prev_hash1, message);
//    //   // 
//    //    preparation_sha256_with_OPAD(pass_xor_opad, prev_hash1, message);
//    //   
//    //   // memcpy(prev_hash_hmac, xor_strs_256bit(prev_hash_hmac, prev_hash1), 4 * 256);
//    //}
//   
//    //return message;
//}

//__global__ void password_xor_with_ipad_opad( uint32_t* pass_xor_ipad, uint32_t* pass_xor_opad)
//{
//    /*password_xor_with_IPAD(password, length, pass_xor_ipad);
//    password_xor_with_OPAD(password, length, pass_xor_opad);*/
//}

__global__ void pbkdf2_hmac_sha256(unsigned int c, uint32_t* password, size_t length, uint32_t* pass_xor_ipad, uint32_t* pass_xor_opad,uint32_t* salt, uint32_t* pbkdf2_hash)
{
   
    uint32_t message[1024]{ 0 };
    uint32_t prev_hash_hmac[256]{ 0 };
    uint32_t zero_str[256]{ 0 };
    uint32_t part_pbkdf2_hash[256]{ 0 };

    for (int k = threadIdx.x + blockIdx.x * blockDim.x; k < count_passwords; k += gridDim.x * blockDim.x)
    {
       for (int i = threadIdx.x + blockIdx.x * blockDim.x; i < 2; i += gridDim.x * blockDim.x)
       {
            //salt[255] = (uint32_t)(i + 1);
            password_xor_with_IPAD(password, length, pass_xor_ipad);
            __syncthreads();
            password_xor_with_OPAD(password, length, pass_xor_opad);
            __syncthreads();
            memcpy(prev_hash_hmac, salt, sizeof(uint32_t) * 256);
            __syncthreads();

            for (auto j = 0; j < c; ++j)
            {
               printf("j=%d\n", j);

                preparation_sha256_with_IPAD(pass_xor_ipad, prev_hash_hmac, message);
                main_loop_sha256(message, prev_hash_hmac);
                preparation_sha256_with_OPAD(pass_xor_opad, prev_hash_hmac, message);
                main_loop_sha256(message, prev_hash_hmac);
                xor_strs(prev_hash_hmac, part_pbkdf2_hash, 256, part_pbkdf2_hash, zero_str);
                /* for (int i = threadIdx.x + blockIdx.x * blockDim.x; i < 256; i += gridDim.x * blockDim.x)
                 {
                     pbkdf2_hash[i] = prev_hash_hmac[i] ^ pbkdf2_hash[i];
                     __syncthreads();
                 }*/
            }
            __syncthreads();
            memcpy(pbkdf2_hash, part_pbkdf2_hash, sizeof(uint32_t) * 256);
            __syncthreads();
         //   __syncthreads();
       }
        __syncthreads();
    }
}




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

void str_to_binary(std::string pass, int *output_binary)
{
    int ascii_number_of_letter = 0;
    int count = pass.size() * 8;
    for (size_t i = 0; i < pass.size(); ++i)
    {
        ascii_number_of_letter = (int)(pass[i]);
        while (ascii_number_of_letter != 0)
        {
            output_binary[count] = ascii_number_of_letter % 2;
            ascii_number_of_letter /= 2;
            count--;
        }
    }

}

int main()
{

    
    unsigned int len_hash_pbkdf2 = 2;
    uint32_t* salt = new uint32_t[256]{ 0 };
   
    std::ifstream file("8digits.txt");
    std::string pass;
    uint32_t binary_passwords[1000][64]{ 0 };
    int count = 0;

    std::string bin_pass;
    if (file.is_open())
    {
        while (!file.eof() && count<1000)
        {
            file >> pass;
            for (std::size_t i = 0; i < pass.size(); ++i)
            {
                bin_pass.append(std::bitset<8>(pass.c_str()[i]).to_string());
            }
            for (std::size_t j = 0; j < bin_pass.size(); ++j)
            {
                binary_passwords[count][j] = uint32_t(bin_pass[j])-48;
            }
            bin_pass.erase();
            count++;
        }

    }

   /* for (auto i = 0; i < 1000; ++i)
    {
        std::cout << "count i-"<<i<<" ";
        for (auto j = 0; j < 64; ++j)
        {
            std::cout << binary_passwords[i][j];
        }
        std::cout << std::endl;
    }*/

  


    uint32_t* password_xor_with_ipad = new uint32_t[512]{ 0 };
    uint32_t* password_xor_with_opad = new uint32_t[512]{ 0 };
    uint32_t* pbkdf2_hash = new uint32_t[len_hash_pbkdf2 * 256]{ 0 };
    uint32_t* dev_password_xor_with_ipad;
    uint32_t* dev_password_xor_with_opad;
    uint32_t* dev_pbkdf2_hash;
    uint32_t* dev_salt;
    uint32_t* dev_binary_passwords;
    

    cudaError_t cudaStatus;
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_binary_passwords, 64 * sizeof(uint32_t));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        //goto Error;
    }
    cudaStatus = cudaMemcpy(dev_binary_passwords, binary_passwords[100], 64 * sizeof(uint32_t), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
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



    



    //cudaStatus = cudaGetLastError();
    //if (cudaStatus != cudaSuccess) {
    //    fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
    //    goto Error;
    //}

    //// cudaDeviceSynchronize waits for the kernel to finish, and returns
    //// any errors encountered during the launch.
    //cudaStatus = cudaDeviceSynchronize();
    //if (cudaStatus != cudaSuccess) {
    //    fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel %s!\n", cudaStatus, cudaGetErrorString(cudaStatus));
    //    goto Error;
    //}

    //cudaStatus = cudaMemcpy(password_xor_with_ipad, dev_password_xor_with_ipad, 512 * sizeof(uint32_t), cudaMemcpyDeviceToHost);
    //if (cudaStatus != cudaSuccess) {
    //    fprintf(stderr, "cudaMemcpy failed!");
    //    goto Error;
    //}

    //cudaStatus = cudaMemcpy(password_xor_with_opad, dev_password_xor_with_opad, 512 * sizeof(uint32_t), cudaMemcpyDeviceToHost);
    //if (cudaStatus != cudaSuccess) {
    //    fprintf(stderr, "cudaMemcpy failed!");
    //    goto Error;
    //}
    //for (auto i = 0; i < 512; ++i)
    //{
    //    std::cout << password_xor_with_ipad[i];
    //}
    //std::cout << std::endl;

    //for (auto i = 0; i < 512; ++i)
    //{
    //    std::cout << password_xor_with_opad[i];
    //}
    //std::cout << std::endl;

    //cudaStatus = cudaDeviceReset();
    //if (cudaStatus != cudaSuccess) {
    //    fprintf(stderr, "cudaDeviceReset failed!");
    //    return 1;
    //}
    //---------------------------------------------------------------------------------------------------------
   /* cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }*/

    cudaStatus = cudaMalloc((void**)&dev_pbkdf2_hash, len_hash_pbkdf2 * 256 * sizeof(uint32_t));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(dev_pbkdf2_hash, pbkdf2_hash, len_hash_pbkdf2 * 256 * sizeof(uint32_t), cudaMemcpyHostToDevice);
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

    
    
        {   

        /* cudaStatus = cudaMalloc((void**)&dev_password_xor_with_ipad, 512 * sizeof(uint32_t));
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
         }*/



       // password_xor_with_ipad_opad << <16, 32 >> > (dev_password, length_passwords, dev_password_xor_with_ipad, dev_password_xor_with_opad);

        //cudaStatus = cudaGetLastError();
        //if (cudaStatus != cudaSuccess) {
        //    fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        //    goto Error;
        //}

        //// cudaDeviceSynchronize waits for the kernel to finish, and returns
        //// any errors encountered during the launch.
        //cudaStatus = cudaDeviceSynchronize();
        //if (cudaStatus != cudaSuccess) {
        //    fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel %s!\n", cudaStatus, cudaGetErrorString(cudaStatus));
        //    goto Error;
        //}

     /*   cudaStatus = cudaMemcpy(password_xor_with_ipad, dev_password_xor_with_ipad, 512 * sizeof(uint32_t), cudaMemcpyDeviceToHost);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto Error;
        }

        cudaStatus = cudaMemcpy(password_xor_with_opad, dev_password_xor_with_opad, 512 * sizeof(uint32_t), cudaMemcpyDeviceToHost);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto Error;
        }*/
       /* for (auto i = 0; i < 512; ++i)
        {
            std::cout << password_xor_with_ipad[i];
        }
        std::cout << std::endl;

        for (auto i = 0; i < 512; ++i)
        {
            std::cout << password_xor_with_opad[i];
        }
        std::cout << std::endl;*/

        pbkdf2_hmac_sha256 << <500, 2 >> > (2000, dev_binary_passwords, 8, dev_password_xor_with_ipad,
            dev_password_xor_with_opad, dev_salt, dev_pbkdf2_hash);

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

        cudaStatus = cudaMemcpy(pbkdf2_hash, dev_pbkdf2_hash, len_hash_pbkdf2 * 256 * sizeof(uint32_t), cudaMemcpyDeviceToHost);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "cudaMemcpy failed!");
            goto Error;
        }

        //main_loop_sha256(message_for_sha256, hash);
        for (auto i = 0; i < 512; ++i)
        {
            std::cout << pbkdf2_hash[i];
        }
        std::cout << std::endl;

    }

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

