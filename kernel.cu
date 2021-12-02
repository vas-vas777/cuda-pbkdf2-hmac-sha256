
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <string>
#include <bitset>
#include <iostream>


const __int64 round_consts[64] = { 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
                            0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
                            0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
                            0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
                            0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
                            0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
                            0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
                            0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2 };


cudaError_t addWithCuda(char* binary_pass, int length_block);

__host__ __int64* to_binary_32bit(__int64 number)
{
    __int64* binary_str = new __int64[32]{ 0 };
    int count = 31;
    //std::cout << number << std::endl;
    while (number!=0)
    {
        //std::cout << count << std::endl;
        binary_str[count] = number % 2;
        number /= 2;
        count--;
    }
    /*for (auto i = 0; i < 32; ++i)
    {
        std::cout << binary_str[i];
    }*/
    return binary_str;
    //delete[] binary_str;
}

__host__ __int64* and_strs_32bit(__int64* str1, __int64* str2)
{
    __int64* result_str = new __int64[32]{ 0 };
    for (auto i = 0; i < 32; ++i)
    {
        result_str[i] = str1[i] & str2[i];
    }
    return result_str;
    //delete[] result_str;
}

__host__ __int64* inverse_str_32bit(__int64* str1)
{
    __int64* result_str = new __int64[32]{ 0 };
    for (auto i = 0; i < 32; ++i)
    {
        result_str[i] = ~str1[i];
    }
    return result_str;
    //delete[] result_str;
}

__host__ __int64 sum_strs_32bit(__int64* str1, __int64* str2)
{
    //__int64* result_sum = new __int64[32]{ 0 };
    __int64 number1 = 0;
    __int64 number2 = 0;
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
    number2 = (number1 + number2) % 4294967296;

    //std::cout << number2 << std::endl;
    return number2;
   // delete[]result_sum;
    //delete[]result_sum;
}

__host__ __int64* xor_strs_32bit(__int64* str1, __int64* str2)
{
    __int64* result_xor = new __int64[32]{ 0 };
    for (auto i = 0; i < 32; ++i)
    {
        result_xor[i] = str1[i] ^ str2[i];
    }
    return result_xor;
    //delete[]result_xor;
}

__host__ __int64* rigth_rotate(__int64* str,unsigned int num)
{
    __int64 last = 0;
    __int64* rotated_str = str;
    for (unsigned int count = 1; count <= num; ++count)
    {
        last = rotated_str[31];
        for (auto i = 31; i > 0; i--)
        {
            rotated_str[i] = rotated_str[i - 1];
        }
        rotated_str[0] = last;
       /* std::cout <<count<< std::endl;
        for (auto i = 0; i < 32; ++i)
        {
            std::cout << rotated_str[i];
        }
        std::cout << std::endl;*/
    }
    
    return rotated_str;
    //delete[] rotated_str;
}

__host__ __int64* rigth_shift(__int64* str, unsigned int num)
{
    //__int64 last = 0;
   // for (auto count = 0; count < num; ++count)
   // {
       // last = str[31];
    __int64* shifted_str = str;
        for (unsigned int i = 31; i > 0; --i)
        {
            if (i >= num)
            {
                shifted_str[i] = shifted_str[i - num];
            }
            else
            {
                shifted_str[i] = 0;
            }
        }
       // str[0] = last;
  //  }
    /*for (auto i = 0; i < 32; ++i)
    {
        std::cout << shifted_str[i];
    }*/
    return shifted_str;
    //delete[] shifted_str;
}



__host__ __int64* password_xor_with_IPAD(char* password,int length)
{
    __int64* binary_str = new __int64[512]{ 0 };
    __int64 IPAD[] = { 0,0,1,1,0,1,1,0 };
    __int64* ipad = new __int64[512]{ 0 };
    for (auto i = 0; i < 512; ++i)
    {
        if (i < 8 * length)
        {
            binary_str[i] = (0 != (password[i / 8] & 1 << (~i & 7)));
        }
        else
        {
            binary_str[i] = 0;
        }
    }
    for (auto i = 0; i < 512; ++i)
    {
        ipad[i] = IPAD[i % 8];
        
    }
   /* for (auto i = 0; i < 512; ++i)
    {
        std::cout << binary_str[i];
    }
    std::cout << std::endl;
    for (auto i = 0; i < 512; ++i)
    {
        std::cout << ipad[i];
    }
    std::cout << std::endl;*/
    for (auto i = 0; i < 512; ++i)
    {
        binary_str[i] = binary_str[i] ^ ipad[i];
    }
    std::cout << "password_xor_with_IPAD 512 bits" << std::endl;
    for (auto i = 0; i < 512; ++i)
    {
        std::cout << binary_str[i];
    }
    std::cout << std::endl;
    //std::cout << sizeof(binary_str) << std::endl;
    
    return binary_str;
   /* delete[] binary_str;
    delete[] ipad;*/
    //std::string binary_str = {};
    //std::string IPAD = {};
    ////std::cout << binary_pass << std::endl;
    //for (auto i = 0; i < 64; ++i) //перевод в двоичную строку пароля
    //{
    //    if (i < password.size())
    //    {
    //        binary_str.append(std::bitset<8>(password.c_str()[i]).to_string());
    //        IPAD.append(std::bitset<8>('0x36').to_string());
    //    }
    //    else
    //    {
    //        binary_str.append(std::bitset<8>(0).to_string());
    //        IPAD.append(std::bitset<8>('0x36').to_string());
    //    }
    //}
    /////std::cout << binary_str << std::endl;
    ////std::cout << std::endl;
    ////std::cout << IPAD << std::endl;
    ////std::cout << binary_str.size() << " " << IPAD.size() << std::endl;
    //binary_str = (std::bitset<512>(binary_str) ^ std::bitset<512>(IPAD)).to_string();
    //return binary_str;
    //std::cout << binary_str << std::endl;
    
}

__host__ __int64* password_xor_with_OPAD(char* password, int length)
{
    __int64* binary_str = new __int64[512]{ 0 };
    __int64 OPAD [] = { 0,1,0,1,1,1,0,0 };
    __int64* opad = new __int64[512]{ 0 };
    for (auto i = 0; i < 512; ++i)
    {
        if (i < 8 * length)
        {
            binary_str[i] = (0 != (password[i / 8] & 1 << (~i & 7)));
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
    /*for (auto i = 0; i < 512; ++i)
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

    
    return binary_str;
    delete[] binary_str;
    delete[] opad;
    //std::string binary_str = {};
    //std::string IPAD = {};
    ////std::cout << binary_pass << std::endl;
    //for (auto i = 0; i < 64; ++i) //перевод в двоичную строку пароля
    //{
    //    if (i < password.size())
    //    {
    //        binary_str.append(std::bitset<8>(password.c_str()[i]).to_string());
    //        IPAD.append(std::bitset<8>('0x5C').to_string());
    //    }
    //    else
    //    {
    //        binary_str.append(std::bitset<8>(0).to_string());
    //        IPAD.append(std::bitset<8>('0x5C').to_string());
    //    }
    //}
    /////std::cout << binary_str << std::endl;
    ////std::cout << std::endl;
    ////std::cout << IPAD << std::endl;
    ////std::cout << binary_str.size() << " " << IPAD.size() << std::endl;
    //binary_str = (std::bitset<512>(binary_str) ^ std::bitset<512>(IPAD)).to_string();
    //return binary_str;
}

 __host__ __int64* preparation_sha256_with_IPAD(__int64* password_xor_with_ipad, __int64*prev_hash)
{
     __int64* binary_str = new __int64[1024]{ 0 };
     memcpy(binary_str, password_xor_with_ipad, 8*512);
    memcpy(binary_str + 512, prev_hash, 8 * 256);
    binary_str[768] = 1;
    binary_str[1014] = 1;
    binary_str[1015] = 1;
    //memmove(binary_str, password_xor_with_ipad, 512);
    std::cout << "preparation_sha256_with_IPAD-1024 bits" << std::endl;
    for (auto i = 0; i < 1024; ++i)
    {
        std::cout << binary_str[i];
    }
    std::cout << std::endl;
    //memcpy(output_message, binary_str, 8 * 1024);//копируем все 1024 бита сообщения
   
    //for (auto i = 0; i < 2048; ++i)
    //{
    //    std::cout << output_message[i];
    //}
    //std::cout << std::endl;
    
    return binary_str;
    
}

__host__ __int64* preparation_sha256_with_OPAD(__int64* password_xor_with_opad, __int64* prev_hash)
{
    __int64* binary_str = new __int64[1024]{ 0 };
   // __int64* output_message = new __int64[2048]{ 0 };
    //memcpy(binary_str, password_xor_with_ipad, 512);
    /*std::cout << std::endl;
    for (auto i = 0; i < 512; ++i)
    {
        std::cout << password_xor_with_opad[i];
    }
    std::cout << std::endl;*/

    memcpy(binary_str, password_xor_with_opad, 8 * 512);
    memcpy(binary_str + 512, prev_hash, 8 * 256);
    binary_str[768] = 1;
    binary_str[1014] = 1;
    binary_str[1015] = 1;
   
    return binary_str;
   
}

__host__ __int64* main_loop_sha256_with_ipad(__int64* message)
{
    __int64* h0 = new __int64[] { 0, 1, 1, 0,  1, 0, 1, 0,  0, 0, 0, 0,  1, 0, 0, 1,  1, 1, 1, 0,  0, 1, 1, 0,  0, 1, 1, 0,  0, 1, 1, 1 };
    __int64* h1 = new __int64[] { 1, 0, 1, 1,  1, 0, 1, 1,  0, 1, 1, 0,  0, 1, 1, 1,  1, 0, 1, 0,  1, 1, 1, 0,  1, 0, 0, 0,  0, 1, 0, 1 };
    __int64* h2 = new __int64[] { 0, 0, 1, 1,  1, 1, 0, 0,  0, 1, 1, 0,  1, 1, 1, 0,  1, 1, 1, 1,  0, 0, 1, 1,  0, 1, 1, 1,  0, 0, 1, 0 };
    __int64* h3 = new __int64[] { 1, 0, 1, 0,  0, 1, 0, 1,  0, 1, 0, 0,  1, 1, 1, 1,  1, 1, 1, 1,  0, 1, 0, 1,  0, 0, 1, 1,  1, 0, 1, 0 };
    __int64* h4 = new __int64[] { 0, 1, 0, 1,  0, 0, 0, 1,  0, 0, 0, 0,  1, 1, 1, 0,  0, 1, 0, 1,  0, 0, 1, 0,  0, 1, 1, 1,  1, 1, 1, 1 };
    __int64* h5 = new __int64[] { 1, 0, 0, 1,  1, 0, 1, 1,  0, 0, 0, 0,  0, 1, 0, 1,  0, 1, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 1, 0, 0 };
    __int64* h6 = new __int64[] { 0, 0, 0, 1,  1, 1, 1, 1,  1, 0, 0, 0,  0, 0, 1, 1,  1, 1, 0, 1,  1, 0, 0, 1,  1, 0, 1, 0,  1, 0, 1, 1 };
    __int64* h7 = new __int64[] { 0, 1, 0, 1,  1, 0, 1, 1,  1, 1, 1, 0,  0, 0, 0, 0,  1, 1, 0, 0,  1, 1, 0, 1,  0, 0, 0, 1,  1, 0, 0, 1 };
    __int64* part_message1 = new __int64[512]{ 0 };
    __int64* part_message2 = new __int64[512]{ 0 };
    memcpy(part_message1, message, 8 * 512);
    memcpy(part_message2, message + 512, 8 * 512);
    std::cout << "message" << std::endl;
    for (auto i = 0; i < 1024; ++i)
    {
        std::cout << message[i];
    }
    std::cout << std::endl;
    std::cout << "part_message1" << std::endl;
    for (auto i = 0; i < 512; ++i)
    {
        std::cout << part_message1[i];
    }
    std::cout << std::endl;
    std::cout << "part_message2" << std::endl;
    for (auto i = 0; i < 512; ++i)
    {
        std::cout << part_message2[i];
    }
    std::cout << std::endl;
    int count = 1;//счётчик для 2ух итераций
    __int64* s0 = new __int64[32]{ 0 };
    __int64* s1 = new __int64[32]{ 0 };
    __int64* S1 = new __int64[32]{ 0 };
    __int64* ch = new __int64[32]{ 0 };
    __int64* temp1 = new __int64[32]{ 0 };
    __int64* S0 = new __int64[32]{ 0 };
    __int64* maj = new __int64[32]{ 0 };
    __int64* temp2 = new __int64[32]{ 0 };

    __int64 sum_ext1_2_s0_s1 = 0;
    //__int64 sum_ext2_s1 = 0;

    __int64* a = 0;
    __int64* b = 0;
    __int64* c = 0;
    __int64* d = 0;
    __int64* e = 0;
    __int64* f = 0;
    __int64* g = 0;
    __int64* h = 0;
   // std::cout << "h0" << std::endl;
   // for (auto i = 0; i < 32; ++i)
   // {
   //     std::cout << h0[i];
   // }
   // std::cout << std::endl;
   ///* std::cout << "h1" << std::endl;
   // for (auto i = 0; i < 32; ++i)
   // {
   //     std::cout << h1[i];
   // }
   // std::cout << std::endl;*/
   // s0 = rigth_shift(h0, 7);
   // for (auto i = 0; i < 32; ++i)
   // {
   //     std::cout << s0[i];
   // }
    /*std::cout << "a" << std::endl;
    
    std::cout << "h1" << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << h1[i];
    }
    s1 = rigth_rotate(h1, 2);
    std::cout << "b" << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << s1[i];
    }
    ch=xor_strs_32bit(rigth_rotate(h0, 7), rigth_rotate(h1, 18));
    std::cout << "c-sum" << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << ch[i];
    }*/
   ///return h0;
    while (count < 3)
    {
        __int64** extend_part_message1 = new __int64* [64];
        for (auto i = 0; i < 64; ++i)
        {
            extend_part_message1[i] = new __int64[32]{ 0 };
        }

        if (count == 1)
        {
            for (auto i = 0; i < 16; ++i)
            {
                memcpy(extend_part_message1[i], part_message1 + (i * 32), 8 * 32);
            }
        }

        if (count == 2)
        {
            for (auto i = 0; i < 16; ++i)
            {
                memcpy(extend_part_message1[i], part_message2 + (i * 32), 8 * 32);
            }
        }
        std::cout << "extend_part_message" << std::endl;
        for (auto i = 0; i < 64; ++i)
        {
            for (auto j = 0; j < 32; ++j)
            {
                std::cout << extend_part_message1[i][j];
            }
            std::cout << std::endl;
        }
        std::cout << std::endl;
        /*std::cout << std::endl;
        std::cout << std::endl;
        std::cout << std::endl;*/

        //__int64* str = new __int64[32]{ 0 };

        // __int64 sum_S0_maj = 0;
        // __int64 res_sum_with_round_const = 0;

         //hex_to_dec(round_consts[0]);

        for (auto i = 16; i < 64; ++i)
        {
            s0 = xor_strs_32bit(xor_strs_32bit(rigth_rotate(extend_part_message1[i - 15], 7),
                rigth_rotate(extend_part_message1[i - 15], 18)),
                rigth_shift(extend_part_message1[i - 15], 3));
            s1 = xor_strs_32bit(xor_strs_32bit(rigth_rotate(extend_part_message1[i - 2], 17),
                rigth_rotate(extend_part_message1[i - 2], 19)),
                rigth_shift(extend_part_message1[i - 2], 10));
            //sum_ext1_s0 = 
            //sum_ext2_s1 = ;
            //std::cout << sum_strs_32bit(extend_part_message1[i - 16], s0) << std::endl;
            //std::cout << sum_strs_32bit(extend_part_message1[i - 7], s1) << std::endl;
            sum_ext1_2_s0_s1 = (sum_strs_32bit(extend_part_message1[i - 16], s0) + sum_strs_32bit(extend_part_message1[i - 7], s1)) % 4294967296;
            extend_part_message1[i] = to_binary_32bit(sum_ext1_2_s0_s1);
            /*for (auto j = 0; j < 32; ++j)
            {
                std::cout << extend_part_message1[i][j];
            }
            std::cout << std::endl;*/
        }
        std::cout << "extend_part_message_after" << std::endl;
        for (auto i = 0; i < 64; ++i)
        {
            for (auto j = 0; j < 32; ++j)
            {
                std::cout << extend_part_message1[i][j];
            }
            std::cout << std::endl;
        }
        std::cout << std::endl;
        a = h0;
        b = h1;
        c = h2;
        d = h3;
        e = h4;
        f = h5;
        g = h6;
        h = h7;


        for (auto i = 0; i < 64; ++i)
        {
            S1 = xor_strs_32bit(xor_strs_32bit(rigth_rotate(e, 6), rigth_rotate(e, 11)),
                rigth_rotate(e, 25));
            ch = xor_strs_32bit(and_strs_32bit(e, f), and_strs_32bit(inverse_str_32bit(e), g));
            /* std::cout << "sum_numbers h,S1" << std::endl;
             std::cout << sum_strs_32bit(h, S1) << std::endl;
             std::cout << "sum_numbers ch,xtend_part_message[i]" << std::endl;
             std::cout << sum_strs_32bit(ch, extend_part_message1[i]) << std::endl;
             std::cout << "round_const[i]" << std::endl;
             std::cout << round_consts[i] << std::endl;
             std::cout << "sum" << std::endl;
             std::cout << (sum_strs_32bit(h, S1) + sum_strs_32bit(ch, extend_part_message1[i]) + round_consts[i]) % 4294967296 << std::endl;*/
            temp1 = to_binary_32bit((sum_strs_32bit(h, S1) + sum_strs_32bit(ch, extend_part_message1[i]) + round_consts[i]) % 4294967296);
            /* for (auto i = 0; i < 32; ++i)
             {
                 std::cout << temp1[i];
             }
             std::cout << std::endl;*/
            S0 = xor_strs_32bit(xor_strs_32bit(rigth_rotate(a, 2), rigth_rotate(a, 13)),
                rigth_rotate(a, 22));
            maj = xor_strs_32bit(xor_strs_32bit(and_strs_32bit(a, b), and_strs_32bit(a, c)),
                and_strs_32bit(b, c));
            temp2 = to_binary_32bit(sum_strs_32bit(S0, maj));
            h = g;
            g = f;
            f = e;
            e = to_binary_32bit(sum_strs_32bit(d, temp1));
            d = c;
            c = b;
            b = a;
            a = to_binary_32bit(sum_strs_32bit(temp1, temp2));
        }
        count++;
        delete[] extend_part_message1;
        delete[] s0;
        delete[] s1;
        delete[] S0;
        delete[] S1;
        delete[] ch;
        delete[] temp1;
        delete[] temp2;
        delete[] maj;

        h0 = to_binary_32bit(sum_strs_32bit(h0, a));
        h1 = to_binary_32bit(sum_strs_32bit(h1, b));
        h2 = to_binary_32bit(sum_strs_32bit(h2, c));
        h3 = to_binary_32bit(sum_strs_32bit(h3, d));
        h4 = to_binary_32bit(sum_strs_32bit(h4, e));
        h5 = to_binary_32bit(sum_strs_32bit(h5, f));
        h6 = to_binary_32bit(sum_strs_32bit(h6, g));
        h7 = to_binary_32bit(sum_strs_32bit(h7, h));

    }
    
    __int64* hash = new __int64[256]{ 0 };
    std::cout <<"h0"<< std::endl;
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
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << h2[i];
    }
    std::cout << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << h3[i];
    }
    std::cout << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << h4[i];
    }
    std::cout << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << h5[i];
    }
    std::cout << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << h6[i];
    }
    std::cout << std::endl;
    for (auto i = 0; i < 32; ++i)
    {
        std::cout << h7[i];
    }
    std::cout << std::endl;
    memcpy(hash, h0, 8 * 32);
    memcpy(hash + 32, h1, 8 * 32);
    memcpy(hash + 64, h2, 8 * 32);
    memcpy(hash + 96, h3, 8 * 32);
    memcpy(hash + 128, h4, 8 * 32);
    memcpy(hash + 160, h5, 8 * 32);
    memcpy(hash + 192, h6, 8 * 32);
    memcpy(hash + 224, h7, 8 * 32);
    return hash;

    
    
       

}

__global__ void addKernel(char* binary_pass, int length_block)
{
    
    


}
int main()
{
   
    std::string password = "1234";
    __int64* password_xor_with_ipad = password_xor_with_IPAD("1234", 4);
    __int64* prev_hash_u = new __int64[256]{ 0 };
    __int64* messsage=preparation_sha256_with_IPAD(password_xor_with_ipad, prev_hash_u);
    __int64* hash=main_loop_sha256_with_ipad(messsage);
    std::cout << "hash" << std::endl;
    for (auto i = 0; i < 256; ++i)
    {
        std::cout << hash[i];
    }
    /*
    __int64* h0 = new __int64[] { 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 1 };
    __int64* h1 = new __int64[] { 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1 };
    __int64* res = new __int64[32];
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
    char* dev_binary_pass = "111";
    cudaError_t cudaStatus;

    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    // Allocate GPU buffers for three vectors (two input, one output)    .
    cudaStatus = cudaMalloc((void**)&dev_binary_pass, length_block *sizeof(char));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

   /* cudaStatus = cudaMalloc((void**)&dev_hash_output, length_block * sizeof(char));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }*/

    /*cudaStatus = cudaMalloc((void**)&dev_b, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }*/

    // Copy input vectors from host memory to GPU buffers.
    cudaStatus = cudaMemcpy(dev_binary_pass, binary_pass, length_block * sizeof(char), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

   /* cudaStatus = cudaMemcpy(dev_b, b, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }*/

    // Launch a kernel on the GPU with one thread for each element.
    addKernel<<<16, 16 >>>(dev_binary_pass,length_block);

    // Check for any errors launching the kernel
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }
    
    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
        goto Error;
    }

    // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(binary_pass, dev_binary_pass, length_block * sizeof(char), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

Error:
    cudaFree(dev_binary_pass);
   // cudaFree(dev_hash_output);
    //cudaFree(dev_b);
    
    return cudaStatus;
}
