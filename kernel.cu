
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include <string>
#include <bitset>
#include <iostream>
//#include <openssl/hmac.h>




cudaError_t addWithCuda(char* binary_pass, int length_block);

__host__ uint32_t* to_binary_32bit(uint32_t number)
{
    uint32_t *binary_str=new uint32_t [32]{ 0 };


    int count = 31;
    //std::cout << number << std::endl;
    while (number!=0)
    {
       
        binary_str[count] = number % 2;
        
        number /= 2;
        count--;
       
    }
   
    
    return binary_str;
    //delete[] binary_str;
}

__host__ uint32_t str_to_32bitnumber(uint32_t* str)
{
    uint32_t number1 = 0;
    for (auto i = 0; i < 32; ++i)
    {
        number1 += str[i] * pow(2, (31 - i));
    }
    return number1;
}

__host__ uint32_t* and_strs_32bit(uint32_t* str1, uint32_t* str2)
{
    uint32_t *result_str = new uint32_t[32]{ 0 };
    for (auto i = 0; i < 32; ++i)
    {
        result_str[i] = str1[i] & str2[i];
    }
    return result_str;
    //delete[] result_str;
}

__host__ uint32_t* inverse_str_32bit(uint32_t* str1)
{
    uint32_t *result_str = new uint32_t[32]{ 0 };
    for (auto i = 0; i < 32; ++i)
    {
        result_str[i] = !str1[i];
        //std::cout << !str1[i];
    }
   // std::cout << std::endl;
    return result_str;
    //delete[] result_str;
}

__host__ uint32_t* inverse_str_256bit(uint32_t* str1)
{
    uint32_t *result_str = new uint32_t[256]{ 0 };
    for (auto i = 0; i < 256; ++i)
    {
        result_str[i] = !str1[i];
        //std::cout << !str1[i];
    }
    // std::cout << std::endl;
    return result_str;
    //delete[] result_str;
}

__host__ uint32_t sum_strs_32bit(uint32_t* str1, uint32_t* str2)
{
    //uint32_t* result_sum = new uint32_t[32]{ 0 };
    uint32_t number1 = 0;
    uint32_t number2 = 0;
    uint32_t res_number = 0;
    for (auto i = 0; i < 32; ++i)
    {
        number1 += str1[i] * pow(2, (31 - i));
    }
    for (auto i = 0; i < 32; ++i)
    {
        number2 += str2[i] * pow(2, (31 - i));
    }
    //std::cout << number1 << std::endl;
    //std::cout << number2 << std::endl;
    res_number = (number1 + number2) % 4294967296;

    //std::cout << number2 << std::endl;
    return res_number;
   // delete[]result_sum;
    //delete[]result_sum;
}

__host__ uint32_t* xor_strs(uint32_t* str1, uint32_t* str2, unsigned int length)
{
    uint32_t *result_xor=new uint32_t[length];
    for (auto i = 0; i < length; ++i)
    {
        result_xor[i] = str1[i] ^ str2[i];
    }
    /*std::cout << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << result_xor[i];
    }
    std::cout << std::endl;*/
    return result_xor;
    //delete[]result_xor;
}

__host__ uint32_t rigth_rotate(uint32_t* str, unsigned int num)
{
    uint32_t number = 0;
    uint32_t *rotated_str = new uint32_t[32]{ 0 };
    memcpy(rotated_str, str, 4 * 32);
    number = str_to_32bitnumber(rotated_str);
    return (number >> num | number << (32 - num));
    
}

__host__ uint32_t rigth_shift(uint32_t* str, unsigned int num)
{
    
    uint32_t shifted_str[32]{ 0 };
    memcpy(shifted_str, str, 4 * 32);
    uint32_t number = str_to_32bitnumber(shifted_str);
    return number >> num;
       
}



__host__ uint32_t* password_xor_with_IPAD(char* password,unsigned int length)
{
    uint32_t *binary_str= new uint32_t[512]{ 0 };
    uint32_t IPAD[] = { 0,0,1,1,0,1,1,0 };
    uint32_t *ipad = new uint32_t[512]{ 0 };
    for (auto i = 0; i < 512; ++i)
    {
        if (i < 8 * length)
        {
           binary_str[i] = (0 != (password[i / 8] & 1 << (~i & 7)));
            ;
        }
        else
        {
            //break;
            binary_str[i] = 0;
        }
    }
    /*std::cout << "password" << std::endl;
    for (auto i = 0; i < 512; ++i)
    {
        std::cout << binary_str[i];
    }
    std::cout << std::endl;*/
    for (auto i = 0; i < 512; ++i)
    {
        ipad[i] = IPAD[i % 8];
        
    }
    for (auto i = 0; i < 512; ++i)
    {
        binary_str[i] = binary_str[i] ^ ipad[i];
    }
   /* std::cout << "password_xor_with_IPAD 512 bits" << std::endl;
    for (auto i = 0; i < 512; ++i)
    {
        std::cout << binary_str[i];
    }
    std::cout << std::endl;*/
    //std::cout << sizeof(binary_str) << std::endl;
   // delete[] ipad;
    return binary_str;
  
    
}

__host__ uint32_t* password_xor_with_OPAD(char* password, unsigned int length)
{
    uint32_t *binary_str = new uint32_t[512]{ 0 };
    uint32_t OPAD [] = { 0,1,0,1,1,1,0,0 };
    uint32_t *opad = new uint32_t[512]{ 0 };
    for (auto i = 0; i < 512; ++i)
    {
        if (i < 8 * length)
        {
           // binary_str[i] = (0 != (password[i / 8] & 1 << (~i & 7)));
            ;
        }
        else
        {
            binary_str[i] = 0;
        }
    }
    for (auto i = 0; i < 512; ++i)
    {
        opad[i] = OPAD[i % 8];

    }
   /* for (auto i = 0; i < 512; ++i)
    {
        std::cout << binary_str[i];
    }
    std::cout << std::endl;
    for (auto i = 0; i < 512; ++i)
    {
        std::cout << opad[i];
    }
    std::cout << std::endl;*/
    for (auto i = 0; i < 512; ++i)
    {
        binary_str[i] = binary_str[i] ^ opad[i];
    }
   /* for (auto i = 0; i < 512; ++i)
    {
        std::cout << binary_str[i];
    }*/

    //delete[] opad;
    return binary_str;
    /*delete[] binary_str;
    delete[] opad;*/
    
}

 __host__ uint32_t* preparation_sha256_with_IPAD(uint32_t* password_xor_with_ipad, uint32_t*prev_hash)
{
     uint32_t *binary_str = new uint32_t[1024]{ 0 };
     memcpy(binary_str, password_xor_with_ipad, 4 * 512);
     memcpy(binary_str + 512, prev_hash, 4 * 256);
    binary_str[768] = 1;
    binary_str[1014] = 1;
    binary_str[1015] = 1;
    return binary_str;
}

__host__ uint32_t* preparation_sha256_with_OPAD(uint32_t* password_xor_with_opad, uint32_t* prev_hash)
{
    uint32_t binary_str[1024]{ 0 };
  

    memcpy(binary_str, password_xor_with_opad, 4 * 512);
    memcpy(binary_str + 512, prev_hash, 4 * 256);
    binary_str[768] = 1;
    binary_str[1014] = 1;
    binary_str[1015] = 1;
   
    return binary_str;
   
}

__host__ uint32_t* main_loop_sha256(uint32_t* message)
{
    const uint32_t round_consts[64] = { 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2 };

    uint32_t* h0 = new uint32_t[] { 0, 1, 1, 0,  1, 0, 1, 0,  0, 0, 0, 0,  1, 0, 0, 1,  1, 1, 1, 0,  0, 1, 1, 0,  0, 1, 1, 0,  0, 1, 1, 1 };
    uint32_t* h1 = new uint32_t[] { 1, 0, 1, 1,  1, 0, 1, 1,  0, 1, 1, 0,  0, 1, 1, 1,  1, 0, 1, 0,  1, 1, 1, 0,  1, 0, 0, 0,  0, 1, 0, 1 };
    uint32_t* h2 = new uint32_t[] { 0, 0, 1, 1,  1, 1, 0, 0,  0, 1, 1, 0,  1, 1, 1, 0,  1, 1, 1, 1,  0, 0, 1, 1,  0, 1, 1, 1,  0, 0, 1, 0 };
    uint32_t* h3 = new uint32_t[] { 1, 0, 1, 0,  0, 1, 0, 1,  0, 1, 0, 0,  1, 1, 1, 1,  1, 1, 1, 1,  0, 1, 0, 1,  0, 0, 1, 1,  1, 0, 1, 0 };
    uint32_t* h4 = new uint32_t[] { 0, 1, 0, 1,  0, 0, 0, 1,  0, 0, 0, 0,  1, 1, 1, 0,  0, 1, 0, 1,  0, 0, 1, 0,  0, 1, 1, 1,  1, 1, 1, 1 };
    uint32_t* h5 = new uint32_t[] { 1, 0, 0, 1,  1, 0, 1, 1,  0, 0, 0, 0,  0, 1, 0, 1,  0, 1, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 1, 0, 0 };
    uint32_t* h6 = new uint32_t[] { 0, 0, 0, 1,  1, 1, 1, 1,  1, 0, 0, 0,  0, 0, 1, 1,  1, 1, 0, 1,  1, 0, 0, 1,  1, 0, 1, 0,  1, 0, 1, 1 };
    uint32_t* h7 = new uint32_t[] { 0, 1, 0, 1,  1, 0, 1, 1,  1, 1, 1, 0,  0, 0, 0, 0,  1, 1, 0, 0,  1, 1, 0, 1,  0, 0, 0, 1,  1, 0, 0, 1 };
    uint32_t part_message1[512]{ 0 };/*{ 0,1,1,0,1,0,0,0, 0,1,1,0,0,1,0,1, 0,1,1,0,1,1,0,0, 0,1,1,0,1,1,0,0, 0,1,1,0,1,1,1,1, 0,0,1,0,0,0,0,0, 0,1,1,1,0,1,1,1, 0,1,1,0,1,1,1,1,
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
   /* std::cout << "message" << std::endl;
    for (auto i = 0; i < 1024; ++i)
    {
        std::cout << message[i];
    }
    std::cout << std::endl;*/
   /* std::cout << "part_message1" << std::endl;
    for (auto i = 0; i < 512; ++i)
    {
        std::cout << part_message1[i];
    }
    std::cout << std::endl;
    std::cout << std::endl;
    std::cout << "part_message2" << std::endl;
    for (auto i = 0; i < 512; ++i)
    {
        std::cout << part_message2[i];
    }
    std::cout << std::endl;*/
    int count = 1;//счётчик для 2ух итераций
   

   
    while (count < 3)
    {
        
        
        uint32_t *S1 = new uint32_t[32]{ 0 };
        uint32_t *ch = new uint32_t[32]{ 0 };
        uint32_t *temp1 = new uint32_t[32]{ 0 };
        uint32_t *S0 = new uint32_t[32]{ 0 };
        uint32_t *maj = new uint32_t[32]{ 0 };
        uint32_t *temp2 = new uint32_t[32]{ 0 };

        
        //uint32_t sum_ext2_s1 = 0;

        uint32_t *a = new uint32_t[32]{ 0 };
        uint32_t *b = new uint32_t[32]{ 0 };
        uint32_t *c = new uint32_t[32]{ 0 };
        uint32_t *d = new uint32_t[32]{ 0 };
        uint32_t *e = new uint32_t[32]{ 0 };
        uint32_t *f = new uint32_t[32]{ 0 };
        uint32_t *g = new uint32_t[32]{ 0 };
        uint32_t *h = new uint32_t[32]{ 0 };
        uint32_t extend_part_message1[64][32];// = new uint32_t * [64];
        /*for (auto i = 0; i < 64; ++i)
        {
            extend_part_message1[i] = new uint32_t[32]{ 0 };
        }*/

        if (count == 1)
        {
            for (auto i = 0; i < 16; ++i)
            {
                memcpy(extend_part_message1[i], part_message1 + (i * 32), 4*32);
            }
        }

        if (count == 2)
        {
            for (auto i = 0; i < 16; ++i)
            {
                memcpy(extend_part_message1[i], part_message2 + (i * 32), 4*32);
            }
        }
       /* std::cout << "extend_part_message" << std::endl;
        for (auto i = 0; i < 64; ++i)
        {
            std::cout << i << "-";
            for (auto j = 0; j < 32; ++j)
            {
                std::cout << extend_part_message1[i][j];
            }
            std::cout << std::endl;
        }
        std::cout << std::endl;*/

        for (auto i = 16; i < 64; ++i)
        {
            uint32_t *s0 = new uint32_t[32]{ 0 };
            uint32_t *s1 = new uint32_t[32]{ 0 };
            uint32_t sum_ext1_2_s0_s1 = 0;
            //std::cout << "start-i=" <<i<<"i-15="<<i-15<< std::endl;
            memcpy(s0, xor_strs(xor_strs(to_binary_32bit(rigth_rotate(extend_part_message1[i - 15], 7)),
                to_binary_32bit(rigth_rotate(extend_part_message1[i - 15], 18)), 32),
                to_binary_32bit(rigth_shift(extend_part_message1[i - 15], 3)), 32), 4 * 32);
            /*std::cout << "s0 - " << std::endl;
            for (auto j = 0; j < 32; ++j)
            {
                std::cout << j;
            }
            std::cout << std::endl;
            for (auto j = 0; j < 32; ++j)
            {
                std::cout << s0[j];
            }
            std::cout << std::endl;
            std::cout << "start2-i=" << i << "i-2=" << i - 2 << std::endl;*/
            memcpy(s1, xor_strs(xor_strs(to_binary_32bit(rigth_rotate(extend_part_message1[i - 2], 17)),
                to_binary_32bit(rigth_rotate(extend_part_message1[i - 2], 19)),32),
                to_binary_32bit(rigth_shift(extend_part_message1[i - 2], 10)),32), 4*32);
            /*std::cout << "s1 - " << std::endl;
            for (auto j = 0; j < 32; ++j)
            {
                std::cout << j;
            }
            std::cout << std::endl;
            for (auto j = 0; j < 32; ++j)
            {
                std::cout << s1[j];
            }
            std::cout << std::endl;
            std::cout << "exte[i-16] - i-16="<<i-16 << std::endl;
            for (auto j = 0; j < 32; ++j)
            {
                std::cout << j;
            }
            std::cout << std::endl;
            for (auto j = 0; j < 32; ++j)
            {
                std::cout << extend_part_message1[i-16][j];
            }
            std::cout << std::endl;
            std::cout << "exte[i-7] - i-7=" << i - 7 << std::endl;
            for (auto j = 0; j < 32; ++j)
            {
                std::cout << j;
            }
            std::cout << std::endl;
            for (auto j = 0; j < 32; ++j)
            {
                std::cout << extend_part_message1[i - 7][j];
            }
            std::cout << std::endl;*/
        
            sum_ext1_2_s0_s1 = (sum_strs_32bit(extend_part_message1[i - 16], s0) + sum_strs_32bit(extend_part_message1[i - 7], s1)) % 4294967296;
            //std::cout << "i-" << i << " " << sum_ext1_2_s0_s1 << std::endl;
            //std::cout << std::endl;
           
            memcpy(extend_part_message1[i], to_binary_32bit(sum_ext1_2_s0_s1), 4*32);
           /* std::cout << "exte[" << i << "]" << std::endl;
            for (auto j = 0; j < 32; ++j)
            {
                std::cout << j;
            }
            std::cout << std::endl;
            for (auto j = 0; j < 32; ++j)
            {
                std::cout << extend_part_message1[i][j];
            }
            std::cout << std::endl;*/
            //delete[] s0;
            //delete[] s1;

        }
        /*std::cout << "extend_part_message_after" << std::endl;
        for (auto i = 0; i < 64; ++i)
        {
            std::cout << i << "- ";
            for (auto j = 0; j < 32; ++j)
            {
                std::cout << extend_part_message1[i][j];
            }
            std::cout << std::endl;
        }
        std::cout << std::endl;*/
       
        memcpy(a, h0, 4*32);
        memcpy(b, h1, 4*32);
        memcpy(c, h2, 4*32);
        memcpy(d, h3, 4*32);
        memcpy(e, h4, 4*32);
        memcpy(f, h5, 4*32);
        memcpy(g, h6, 4*32);
        memcpy(h, h7, 4*32);
      
        for (auto i = 0; i < 64; ++i)
        {
         
            memcpy(S1, xor_strs(xor_strs(to_binary_32bit(rigth_rotate(e, 6)), to_binary_32bit(rigth_rotate(e, 11)),32),
                to_binary_32bit(rigth_rotate(e, 25)),32), 4*32);
            memcpy(ch, xor_strs(and_strs_32bit(e, f), and_strs_32bit(inverse_str_32bit(e), g),32), 4*32);
           
            memcpy(temp1, to_binary_32bit((sum_strs_32bit(h, S1) + sum_strs_32bit(ch, extend_part_message1[i]) + round_consts[i]) % 4294967296), 4*32);
           
            memcpy(S0, xor_strs(xor_strs(to_binary_32bit(rigth_rotate(a, 2)), to_binary_32bit(rigth_rotate(a, 13)),32),
                to_binary_32bit(rigth_rotate(a, 22)),32), 4*32);
          
            memcpy(maj, xor_strs(xor_strs(and_strs_32bit(a, b), and_strs_32bit(a, c),32),
                and_strs_32bit(b, c),32), 4*32);
          
            memcpy(temp2, to_binary_32bit(sum_strs_32bit(S0, maj)), 4*32);
          
            memcpy(h, g, 4*32);
           
            memcpy(g, f, 4*32);
          
            memcpy(f, e, 4*32);
            memcpy(e, to_binary_32bit(sum_strs_32bit(d, temp1)), 4*32);
            
            memcpy(d, c, 4*32);
            memcpy(c, b, 4*32);
            memcpy(b, a, 4*32);
          
            memcpy(a, to_binary_32bit(sum_strs_32bit(temp1, temp2)), 4*32);
           
        }
        count++;
       
        memcpy(h0, to_binary_32bit(sum_strs_32bit(h0, a)), 4*32);
        memcpy(h1, to_binary_32bit(sum_strs_32bit(h1, b)), 4*32);
        memcpy(h2, to_binary_32bit(sum_strs_32bit(h2, c)), 4*32);
        memcpy(h3, to_binary_32bit(sum_strs_32bit(h3, d)), 4*32);
        memcpy(h4, to_binary_32bit(sum_strs_32bit(h4, e)), 4*32);
        memcpy(h5, to_binary_32bit(sum_strs_32bit(h5, f)), 4*32);
        memcpy(h6, to_binary_32bit(sum_strs_32bit(h6, g)), 4*32);
        memcpy(h7, to_binary_32bit(sum_strs_32bit(h7, h)), 4*32);
        /*delete[] a;
        delete[] b;
        delete[] c;
        delete[] d;
        delete[] e;
        delete[] f;
        delete[] g;
        delete[] h;
        delete[] S0;
        delete[] S1;
        delete[] temp1;
        delete[] temp2;
        delete[] maj;
        delete[] ch;*/


               
    }
    /*std::cout << "h0" << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << h0[i];
    }
    std::cout << std::endl;
    std::cout << "h1" << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << h1[i];
    }
    std::cout << std::endl;
    std::cout << "h2" << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << h2[i];
    }
    std::cout << std::endl;
    std::cout << "h3" << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << h3[i];
    }
    std::cout << std::endl;
    std::cout << "h4" << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << h4[i];
    }
    std::cout << std::endl;
    std::cout << "h5" << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << h5[i];
    }
    std::cout << std::endl;
    std::cout << "h6" << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << h6[i];
    }
    std::cout << std::endl;
    std::cout << "h7" << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << h7[i];
    }
    std::cout << std::endl;*/
    uint32_t *hash = new uint32_t[256]{ 0 };
    memcpy(hash, h0, 4*32);
    memcpy(hash + 32, h1, 4*32);
    memcpy(hash + 64, h2, 4*32);
    memcpy(hash + 96, h3, 4*32);
    memcpy(hash + 128, h4, 4*32);
    memcpy(hash + 160, h5, 4*32);
    memcpy(hash + 192, h6, 4*32);
    memcpy(hash + 224, h7, 4*32);
    /*delete[] h0;
    delete[] h1;
    delete[] h2;
    delete[] h3;
    delete[] h4;
    delete[] h5;
    delete[] h6;
    delete[] h7;*/

    return hash;
}

__host__ uint32_t* hmac_sha256( uint32_t* salt, uint32_t* password_xor_with_ipad, uint32_t* password_xor_with_opad)
{
    uint32_t *prev_hash = new uint32_t[256]{ 0 };
    uint32_t *hmac_hash = new uint32_t[256]{ 0 };
    memcpy(prev_hash, salt, 4 * 256);
    uint32_t message[1024]{ 0 };
    memcpy(message, preparation_sha256_with_IPAD(password_xor_with_ipad, prev_hash), 4 * 1024);
    memcpy(prev_hash, main_loop_sha256(message), 4 * 256);
    memcpy(message, preparation_sha256_with_OPAD(password_xor_with_opad, prev_hash), 4 * 1024);
    memcpy(hmac_hash, main_loop_sha256(message), 4 * 256);
   // delete[] prev_hash;
  //  delete[] message;

    return hmac_hash;
   


}

__host__ uint32_t* pbkdf2_hmac_sha256(char* password, unsigned int length, unsigned int c)
{
    
    uint32_t *hash = new uint32_t[256]{ 0 };
    uint32_t *salt = new uint32_t[256]{ 0 };
    uint32_t *prev_hash = new uint32_t[256]{ 0 };
    //uint32_t* temp = new uint32_t[256]{ 0 };

    uint32_t password_xor_with_ipad[512]{ 0 };
    uint32_t password_xor_with_opad[512]{ 0 };

    memcpy(password_xor_with_ipad, password_xor_with_IPAD(password, length), 4 * 512);
    memcpy(password_xor_with_opad, password_xor_with_OPAD(password, length), 4 * 512);
   // int index = threadIdx.x + blockIdx.x*blockDim.x;
    uint32_t dklen = 256;
    uint32_t len = dklen / 256;
    uint32_t r = dklen - (len - 1) * 256;
   
    for (auto index = 0; index < len; ++index)
    {
        salt[255] = index;
        memcpy(prev_hash, salt, 4 * 256);
        uint32_t temp_hash[256]{ 0 };
        for (auto j = 0; j < c; ++j)
        {
            memcpy(prev_hash, hmac_sha256(prev_hash, password_xor_with_ipad, password_xor_with_opad), 4 * 256);
            memcpy(temp_hash, xor_strs(temp_hash, prev_hash,256), 4 * 256);
        }
       
        memcpy(hash + index * 256, temp_hash, 4 * 256);
    }
    /*delete[] salt;
    delete[] prev_hash;
    delete[] password_xor_with_ipad;
    delete[] password_xor_with_opad;*/
    return hash;

}

__global__ void addKernel(char* password, unsigned int length, unsigned int c, uint32_t* output_hash)
{
    ////int index = threadIdx.x + blockIdx.x;
    //uint32_t* password_xor_with_ipad = new uint32_t[512]{ 0 };
    //uint32_t* password_xor_with_opad = new uint32_t[512]{ 0 };
    //uint32_t* message = new uint32_t[1024]{ 0 };
    //uint32_t* prev_hash = new uint32_t[256]{ 0 };
    //memcpy(password_xor_with_ipad, password_xor_with_IPAD(password, length), 4 * 512);
    ////memcpy(password_xor_with_opad, password_xor_with_OPAD(password, length), 4 * 512);
    //memcpy(message, preparation_sha256_with_IPAD(password_xor_with_ipad, prev_hash), 4 * 1024);
    //


    //memcpy(output_hash, main_loop_sha256(message), 4 * 256);
   /* delete[] message;
    delete[] prev_hash;
    delete[] password_xor_with_ipad;
    delete[] password_xor_with_opad;*/
}
int main()
{
   
    std::string password = "1234";
    //char* password = "1234";
    //uint32_t* password_xor_with_ipad = new uint32_t[512]{ 0 };
    //memcpy(password_xor_with_ipad, password_xor_with_IPAD("1234", 4), 4 * 512);
    //uint32_t* prev_hash_u = new uint32_t[256]{ 0 };
    //uint32_t* messsage = new uint32_t[1024]{ 0 };
    uint32_t* hash = new uint32_t[256]{ 0 };

    //memcpy(messsage, preparation_sha256_with_IPAD(password_xor_with_ipad, prev_hash_u), 4 * 1024);
    memcpy(hash, pbkdf2_hmac_sha256("1234", 4, 4096), 4 * 256);
    std::cout << "hash" << std::endl;
    for (auto i = 0; i < 256; ++i)
    {
        std::cout << hash[i];
    }
   // uint32_t* messsage=preparation_sha256_with_IPAD(password_xor_with_ipad, prev_hash_u);
    //std::cout << sizeof(uint32_t) << std::endl;
    //uint32_t* hash = new uint32_t[256]{ 0 };
    //uint32_t* device_hash;
    //cudaError_t cudaStatus;
    //cudaStatus = cudaSetDevice(0);
    //    if (cudaStatus != cudaSuccess) {
    //        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
    //        //goto Error;
    //    }
    //    //cudaStatus = cudaMalloc((void**)&hash, 256 * sizeof(uint32_t));
    //    //if (cudaStatus != cudaSuccess) {
    //    //    fprintf(stderr, "cudaMalloc failed!");
    //    //    //goto Error;
    //    //}
    //cudaStatus=cudaMalloc((void**)&device_hash, 256* sizeof(uint32_t));
    //    if (cudaStatus != cudaSuccess) {
    //    fprintf(stderr, "cudaMalloc failed!");
    //    //goto Error;
    //}
    //    cudaStatus = cudaMemcpy(device_hash, hash, 256*sizeof(uint32_t),cudaMemcpyHostToDevice);
    //    if (cudaStatus != cudaSuccess) {
    //    fprintf(stderr, "cudaMemcpy failed!");
    //    //goto Error;
    //}
    //addKernel <<<4,512>>> ("1234", 4, 10000, device_hash);
   
    ////Check for any errors launching the kernel
    //cudaStatus = cudaGetLastError();
    //if (cudaStatus != cudaSuccess) {
    //    fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
    // //   goto Error;
    //}
    //
    //// cudaDeviceSynchronize waits for the kernel to finish, and returns
    //// any errors encountered during the launch.
    //cudaStatus = cudaDeviceSynchronize();
    //if (cudaStatus != cudaSuccess) {
    //    fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel %s!\n", cudaStatus, cudaGetErrorString(cudaStatus));
    //   // goto Error;
    //}

    //// Copy output vector from GPU buffer to host memory.
    //cudaStatus = cudaMemcpy(hash, device_hash, 256 * sizeof(uint32_t), cudaMemcpyDeviceToHost);
    //if (cudaStatus != cudaSuccess) {
    //    fprintf(stderr, "cudaMemcpy failed!");
    //   // goto Error;
    //}
    //cudaDeviceSynchronize();
    //uint32_t* fin_hash = new uint32_t[4*256]{ 0 };
    //memcpy(fin_hash, hash, 256 * 4);
    //cudaDeviceReset();
    //memcpy(hash, pbkdf2_hmac_sha256("1234", 4, 400),4 * 256);
    //uint32_t* hash=main_loop_sha256_with_ipad(messsage);
    
    // cudaDeviceReset must be called before exiting in order for profiling and
    // tracing tools such as Nsight and Visual Profiler to show complete traces.
   /* cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
        return 1;
    }*/
    //free(device_hash);
   // delete[] hash;

  /* uint32_t* h0 = new uint32_t[] { 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1 };
   uint32_t* res = new uint32_t[32]{ 0 };
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << h0[i];
    }
    std::cout << std::endl;
    std::cout << sizeof(uint32_t) << std::endl;
    memcpy(res, to_binary_32bit(rigth_rotate(h0, 10)), 4 * 32);
    std::cout << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << res[i];
    }
    std::cout << std::endl;
    std::cout << rigth_rotate(h0, 10) << std::endl;*/
   /* uint32_t* h0 = new uint32_t[] { 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 1 };
    uint32_t* h1 = new uint32_t[] { 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1 };
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << h0[i];
    }
    std::cout << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << h1[i];
    }
    std::cout << std::endl;
    uint32_t* prev_hash_u;
    uint32_t number = 0;
    prev_hash_u = rigth_rotate(h0, 32);
    std::cout << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << prev_hash_u[i];
    }*/
   // std::wcout << number << std::endl;
   
    /*
    uint32_t* h0 = new uint32_t[] { 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 1 };
    uint32_t* h1 = new uint32_t[] { 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1 };
    uint32_t* res = new uint32_t[32];
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << h0[i];
    }
    std::cout << std::endl;
    res = rigth_shift(h0, 5);
    
    std::cout << "res" << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << res[i];
    }*/
    //password_xor_with_IPAD("1234", 4);
    // Add vectors in parallel.
    /*cudaError_t cudaStatus = addWithCuda(bin_str_512, 512);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addWithCuda failed!");
        return 1;
    }*/

   /* printf("{1,2,3,4,5} + {10,20,30,40,50} = {%d,%d,%d,%d,%d}\n",
        c[0], c[1], c[2], c[3], c[4]);*/
   

    //// cudaDeviceReset must be called before exiting in order for profiling and
    //// tracing tools such as Nsight and Visual Profiler to show complete traces.
    //cudaStatus = cudaDeviceReset();
    //if (cudaStatus != cudaSuccess) {
    //    fprintf(stderr, "cudaDeviceReset failed!");
    //    return 1;
    //}

    return 0;
}

// Helper function for using CUDA to add vectors in parallel.
cudaError_t addWithCuda(char* binary_pass, int length_block)
{
    /*int *dev_a = 0;
    int *dev_b = 0;
    int *dev_c = 0;*/
    //char* dev_hash_output = "1111";
   // char* dev_binary_pass = "111";
    cudaError_t cudaStatus;

//    // Choose which GPU to run on, change this on a multi-GPU system.
//    cudaStatus = cudaSetDevice(0);
//    if (cudaStatus != cudaSuccess) {
//        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
//        goto Error;
//    }
//
//    // Allocate GPU buffers for three vectors (two input, one output)    .
//    cudaStatus = cudaMalloc((void**)&dev_binary_pass, length_block *sizeof(char));
//    if (cudaStatus != cudaSuccess) {
//        fprintf(stderr, "cudaMalloc failed!");
//        goto Error;
//    }
//
//   /* cudaStatus = cudaMalloc((void**)&dev_hash_output, length_block * sizeof(char));
//    if (cudaStatus != cudaSuccess) {
//        fprintf(stderr, "cudaMalloc failed!");
//        goto Error;
//    }*/
//
//    /*cudaStatus = cudaMalloc((void**)&dev_b, size * sizeof(int));
//    if (cudaStatus != cudaSuccess) {
//        fprintf(stderr, "cudaMalloc failed!");
//        goto Error;
//    }*/
//
//    // Copy input vectors from host memory to GPU buffers.
//    cudaStatus = cudaMemcpy(dev_binary_pass, binary_pass, length_block * sizeof(char), cudaMemcpyHostToDevice);
//    if (cudaStatus != cudaSuccess) {
//        fprintf(stderr, "cudaMemcpy failed!");
//        goto Error;
//    }
//
//   /* cudaStatus = cudaMemcpy(dev_b, b, size * sizeof(int), cudaMemcpyHostToDevice);
//    if (cudaStatus != cudaSuccess) {
//        fprintf(stderr, "cudaMemcpy failed!");
//        goto Error;
//    }*/
//
//    // Launch a kernel on the GPU with one thread for each element.
//    addKernel<<<16, 16 >>>(dev_binary_pass,length_block);
//
//    // Check for any errors launching the kernel
//    cudaStatus = cudaGetLastError();
//    if (cudaStatus != cudaSuccess) {
//        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
//        goto Error;
//    }
//    
//    // cudaDeviceSynchronize waits for the kernel to finish, and returns
//    // any errors encountered during the launch.
//    cudaStatus = cudaDeviceSynchronize();
//    if (cudaStatus != cudaSuccess) {
//        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
//        goto Error;
//    }
//
//    // Copy output vector from GPU buffer to host memory.
//    cudaStatus = cudaMemcpy(binary_pass, dev_binary_pass, length_block * sizeof(char), cudaMemcpyDeviceToHost);
//    if (cudaStatus != cudaSuccess) {
//        fprintf(stderr, "cudaMemcpy failed!");
//        goto Error;
//    }
//
//Error:
//    cudaFree(dev_binary_pass);
//   // cudaFree(dev_hash_output);
//    //cudaFree(dev_b);
    
    return cudaStatus;
}
