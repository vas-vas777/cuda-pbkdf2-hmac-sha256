#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "cuda_runtime_api.h"
#include <cuda.h>
#include <random>
#include <string>
#include <bitset>
#include <iostream>
#include <fstream>
#include <chrono>


constexpr auto count_passwords = 100;
constexpr auto count_iterations = 10;
constexpr auto length_password = 64;
constexpr auto lenght_hash = 256;
//constexpr auto lenght_hash = 1;



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



__device__ uint32_t sum_strs_32bit(uint32_t *str1, uint32_t *str2)
{
    uint32_t number1[1]{ 0 };
    uint32_t number2[1]{ 0 };
   
    uint32_t res_number = 0;
    for (auto i = 0; i < 32; ++i)
    {
        atomicAdd(&number1[0], str1[i] * __powf(2, (31 - i)));
        atomicAdd(&number2[0], str2[i] * __powf(2, (31 - i)));
    }
    res_number = ((number1[0]) + (number2[0])) % 4294967296;
    return res_number;
   
}


__device__ void xor_strs(uint32_t* str1, uint32_t* str2, unsigned int length, uint32_t* result_xor, uint32_t* str3)
{
   
    for (auto i = 0; i <length; ++i)   
    {
        result_xor[i] = str1[i] ^ str2[i];
        result_xor[i] = result_xor[i] ^ str3[i];
    }
    
}




__device__ void password_xor_with_IPAD(uint32_t* password,size_t length, uint32_t* output_str)
{
    uint32_t binary_str[512]{ 0 };
    memcpy(binary_str, password, sizeof(uint32_t) * length_password);
    
    uint32_t IPAD[] = { 0,0,1,1,0,1,1,0 };

  
    
    for (int i = 0; i < 512; ++i)
    {
        output_str[i] = binary_str[i] ^ IPAD[i % 8];
      //  __syncthreads();
    }
  //  __syncthreads();
    
}

__device__ void password_xor_with_OPAD(uint32_t* password, size_t length, uint32_t *output_str)
{
    uint32_t binary_str[512]{ 0 };
    uint32_t OPAD[] = { 0,1,0,1,1,1,0,0 };
    memcpy(binary_str, password, sizeof(uint32_t) * length_password);
   
   // __syncthreads();
    for (int k = 0; k < 512; ++k)
    {
        output_str[k] = binary_str[k] ^ OPAD[k % 8];
       // __syncthreads();
    }
   // __syncthreads();
}

 __device__ void preparation_sha256_with_IPAD(uint32_t* password_xor_with_ipad, uint32_t*prev_hash, uint32_t *output_str)
{
     uint32_t message[1024]{ 0 };
     for (int k = 0; k < 512; ++k)
     {
         
         message[k] = password_xor_with_ipad[k];
        // __syncthreads();
     }

     for (int k = 0; k < 256; ++k)
     {
         message[k + 512] = prev_hash[k];
       //  __syncthreads();
     }
     // __syncthreads();
     message[768] = 1;
     message[1014] = 1;
     message[1015] = 1;
     for (int k = 0; k < 1024; ++k)
     {
         output_str[k] = message[k];
       //  __syncthreads();
     }
}

__device__ void preparation_sha256_with_OPAD(uint32_t* password_xor_with_opad, uint32_t* prev_hash, uint32_t* output_str)
{
    uint32_t message[1024]{ 0 };
    for (int k = 0; k < 512; ++k)
    {
        
        message[k] = password_xor_with_opad[k];
       // __syncthreads();
    }

    for (int k = 0; k < 256; ++k)
    {
       
        message[k + 512] = prev_hash[k];
       // __syncthreads();
    }

    message[768] = 1;
    message[1014] = 1;
    message[1015] = 1;
    for (int j = 0; j < 1024; ++j)
    {

        output_str[j] = message[j];
       // __syncthreads();
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
       
    uint32_t part_message1[512]{ 0 };
    uint32_t part_message2[512]{ 0 };
    memcpy(part_message1, message, 4 * 512);
    memcpy(part_message2, message + 512, 4 * 512);

    int count = 1;//счётчик для 2ух итераций



    while (count < 3)
    {


     
        uint32_t temp1[32]{ 0 };
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
           
          

        }
       
       
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


       
            uint32_t to_binary_32bit2[32]{ 0 };
            uint32_t to_binary_32bit3[32]{ 0 };
           

           
            

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

    uint32_t hash[256]{ 0 };
    memcpy(hash, h0, 4 * 32);
    memcpy(hash + 32, h1, 4 * 32);
    memcpy(hash + 64, h2, 4 * 32);
    memcpy(hash + 96, h3, 4 * 32);
    memcpy(hash + 128, h4, 4 * 32);
    memcpy(hash + 160, h5, 4 * 32);
    memcpy(hash + 192, h6, 4 * 32);
    memcpy(hash + 224, h7, 4 * 32);
    memcpy(output_hash, hash, 4 * 256);
   

}



//__device__ void found_pass(uint32_t *password, int k)
//{
//    for (size_t i = 0; i < 64; i++)
//    {
//        password[i] = password[i] + k;
//        printf("%u", password[i]);
//    }
//}




__global__ void pbkdf2_hmac_sha256(unsigned int c, 
    uint32_t* password, size_t length, uint32_t* salt, uint32_t* search_hash_pbkdf2, uint32_t* pbkdf2_hashes)
{
   
     uint32_t message[1024]{ 0 };
     uint32_t prev_hash_hmac[256]{ 0 };
     uint32_t zero_str[256]{ 0 };
     uint32_t part_pbkdf2_hash[lenght_hash]{ 0 };
     uint32_t password_xor_ipad[512]{ 0 };
     uint32_t password_xor_opad[512]{ 0 };
     uint32_t current_password[64]{ 0 };
    // bool password_found = false;
    

     for (int k = blockIdx.x * blockDim.x + threadIdx.x;
         k < count_passwords;
         k += blockDim.x * gridDim.x)
     {
         
         memcpy(current_password, password + k * length_password, sizeof(uint32_t) * length_password);
         

         password_xor_with_IPAD(current_password, length, password_xor_ipad);
       //  __syncthreads();
         password_xor_with_OPAD(current_password, length, password_xor_opad);
       //  __syncthreads();
         memcpy(prev_hash_hmac, salt, sizeof(uint32_t) * 256);
       //  __syncthreads();
         for (auto j = 0; j < c; ++j)
         {
             

             preparation_sha256_with_IPAD(password_xor_ipad, prev_hash_hmac, message);
           //  __syncthreads();
             main_loop_sha256(message, prev_hash_hmac);
           //  __syncthreads();
             preparation_sha256_with_OPAD(password_xor_opad, prev_hash_hmac, message);
           //  __syncthreads();
             main_loop_sha256(message, prev_hash_hmac);
           //  __syncthreads();
             xor_strs(prev_hash_hmac, part_pbkdf2_hash, 256, part_pbkdf2_hash, zero_str);
          //   __syncthreads();
             //  __threadfence();
               //  __threadfence();
         }
        // __syncthreads();
         memcpy(pbkdf2_hashes + k * 256, part_pbkdf2_hash, sizeof(uint32_t) * 256);
       //  __syncthreads();

        
     }
        

}


__global__ void search_current_hash_in_hashes(uint32_t * search_hash_pbkdf2, uint32_t* pbkdf2_hashes, uint32_t* position_found)
{
  //  uint32_t temp_hash_pbkdf2[lenght_hash]{ 0 };
    //auto flag = false;

    for (int k = blockIdx.x * blockDim.x + threadIdx.x;
        k < count_passwords*lenght_hash;
        k += blockDim.x * gridDim.x)
    {
      //  memcpy(temp_hash_pbkdf2, pbkdf2_hashes + blockIdx.x * lenght_hash, sizeof(uint32_t) * lenght_hash);
        
        if (pbkdf2_hashes[k] != search_hash_pbkdf2[threadIdx.x])
        {
           position_found[blockIdx.x] = count_passwords;
          // flag = true;
        }
      //  printf("\npos=%d", position_found[43]);
        if (position_found[blockIdx.x] == 0)
        {
            position_found[0] = blockIdx.x;
        }
      
    }
}



//uint32_t* random_salt(size_t Nbits)
//{
//    std::random_device rd;  //Will be used to obtain a seed for the random number engine
//    std::mt19937 gen(rd());
//    std::uniform_int_distribution<> int1(0, 1);
//    uint32_t* str = new uint32_t[Nbits];
//    //str.reserve(Nbits);
//    for (size_t i = 0; i < Nbits; i++)
//    {
//        str[i] = int1(gen) ? 1 : 0;
//    }
//    return str;
//};



int main()
{


    unsigned int len_hash_pbkdf2 = 2;
    uint32_t* salt = new uint32_t[256]{ 0 };

    std::ifstream file("8digits.txt");
    std::string pass{ 0 };
    std::string list_of_passwords;
    uint32_t binary_passwords[length_password * count_passwords]{ 0 };
    int count = 0;

    std::string bin_pass;
    std::cout << "passwords" << std::endl;
    if (file.is_open())
    {
        while (!file.eof() && count < length_password * count_passwords)
        {
            file >> pass;
            list_of_passwords.append(pass);
            std::cout << "count=" << count / 64 << " " << pass << std::endl;
            for (std::size_t i = 0; i < pass.size(); ++i)
            {
                // std::cout << std::bitset<8>(pass.c_str()[i]).to_string();
                bin_pass.append(std::bitset<8>(pass.c_str()[i]).to_string());
            }
            // std::cout << std::endl;
            for (std::size_t j = 0; j < bin_pass.size(); ++j)
            {
                binary_passwords[count] = uint32_t(bin_pass[j]) - 48;
                count++;
            }
            bin_pass.erase();

        }

    }
    std::cout << std::endl;
    //auto t2 = std::chrono::high_resolution_clock::now();
    for (auto i = 0; i < length_password * count_passwords; ++i)
    {

        if (i % 64 == 0)
        {
            std::cout << std::endl;
            std::cout << "count i=" << i / 64 << " ";
            std::cout << binary_passwords[i];

        }
        else
        {
            std::cout << binary_passwords[i];
        }


        // std::cout << std::endl;
    }
    std::cout << std::endl;
    //std::cout << std::endl;
  //  return 0;




    uint32_t pbkdf2_hash[count_passwords * lenght_hash]{ 0 };
    uint32_t search_hash_pbkdf2[lenght_hash]{ 0,0,1,1,1,1,0,0,0,1,1,1,0,1,0,1,0,0,1,1,0,1,1,0,1,1,0,0,1,
        1,0,0,1,0,1,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,0,0,0,1,0,1,1,0,0,1,1,0,1,0,1,1,1,1,0,1,0,0,1,0,1,0,0,0,1,0,0,1,1,1,1,1,1,1,
        0,1,1,0,0,1,0,0,0,0,1,1,1,0,0,1,1,1,1,0,0,0,0,1,0,0,0,1,0,1,1,1,0,1,1,1,0,0,0,1,1,0,0,1,1,1,0,1,1,0,1,0,0,1,1,0,1,0,1,
        0,1,0,1,1,1,1,1,0,1,0,1,1,0,1,1,1,1,0,1,0,0,0,0,1,0,0,1,1,0,1,1,0,0,0,0,0,0,1,1,1,1,1,0,0,1,0,0,1,1,0,0,1,0,1,0,0,0,0,
        0,0,0,1,0,0,1,0,1,0,0,1,1,0,0,1,0,0,1,1,1,0,0,1,1,1,1,1,0,1,0,1,1,0,1,1,1,0,1,0,1,1,1,1,0,1,0,1,0,0, };
    uint32_t found_password[length_password]{ 0 };
    uint32_t hash_found[lenght_hash]{ 0 };
    uint32_t* position_found[1]{ 0 };
    uint32_t* dev_password_xor_with_ipad = nullptr;
    uint32_t* dev_password_xor_with_opad = nullptr;
    uint32_t* dev_pbkdf2_hash = nullptr;
    uint32_t* dev_search_hash_pbkdf2 = nullptr;
    uint32_t* dev_salt = nullptr;
    uint32_t* dev_binary_password = nullptr;
    uint32_t* dev_hash_found = nullptr;
    uint32_t* dev_position_found = nullptr;

    /*cudaDeviceProp deviceProp;*/
    cudaError_t cudaStatus;
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }
    /*cudaGetDeviceProperties(&deviceProp, 0);
    std::cout << deviceProp.maxThreadsPerBlock << std::endl;
    std::cout << std::hex<<deviceProp.maxThreadsDim << std::endl;*/
    

    cudaStatus = cudaMalloc((void**)&dev_binary_password, length_password * count_passwords * sizeof(uint32_t));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        //goto Error;
    }
    cudaStatus = cudaMemcpy(dev_binary_password, binary_passwords, length_password * count_passwords * sizeof(uint32_t), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

        cudaStatus = cudaMalloc((void**)&dev_pbkdf2_hash, count_passwords * lenght_hash * sizeof(uint32_t));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(dev_pbkdf2_hash, pbkdf2_hash, count_passwords * lenght_hash * sizeof(uint32_t), cudaMemcpyHostToDevice);
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


    pbkdf2_hmac_sha256 << <count_passwords, 1 >> > (count_iterations,
        dev_binary_password, 8, dev_salt, dev_search_hash_pbkdf2, dev_pbkdf2_hash);

    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel %s!\n", cudaStatus, cudaGetErrorString(cudaStatus));
        goto Error;
    }
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }
 
    cudaStatus = cudaMalloc((void**)&dev_position_found, sizeof(uint32_t));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }
    cudaStatus = cudaMemcpy(dev_position_found, position_found, sizeof(uint32_t), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_search_hash_pbkdf2, lenght_hash * sizeof(uint32_t));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }
    cudaStatus = cudaMemcpy(dev_search_hash_pbkdf2, search_hash_pbkdf2, lenght_hash * sizeof(uint32_t), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    
    cudaEventRecord(start);

   search_current_hash_in_hashes << <count_passwords, lenght_hash >> > (dev_search_hash_pbkdf2, dev_pbkdf2_hash, dev_position_found);

    cudaEventRecord(stop);


    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel %s!\n", cudaStatus, cudaGetErrorString(cudaStatus));
        goto Error;
    }
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }

    cudaEventRecord(stop);
    cudaStatus = cudaMemcpy(position_found, dev_position_found, sizeof(uint32_t), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }


    cudaEventSynchronize(stop);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);
    std::cout << "milliseconds=" << milliseconds << std::endl;

   


   
  //  std::cout << "position=" << int(position_found[0]) << std::endl;
    if ((int)position_found[0] == count_passwords)
    {
        std::cout << "password not found" << std::endl;
    }
    else
    {
        std::cout << "position=" << int(position_found[0]) << std::endl;
        std::cout << "password" << std::endl;
        for (auto i = int(position_found[0]) * 8; i < int(position_found[0]) * 8 + 8; ++i)
        {
            std::cout << list_of_passwords[i];
        }
        std::cout << std::endl;
    }
    /*cudaStatus = cudaMemcpy(pbkdf2_hash, dev_pbkdf2_hash, count_passwords * 256 * sizeof(uint32_t), cudaMemcpyDeviceToHost);
     if (cudaStatus != cudaSuccess) {
         fprintf(stderr, "cudaMemcpy failed!");
         goto Error;
     }

   
     auto found_pass = false;
     uint32_t temp_hash[256]{ 0 };
    auto t1 = std::chrono::high_resolution_clock::now();
    for (auto i = 0; i < count_passwords; ++i)
    {
        memcpy(temp_hash, pbkdf2_hash + i * 256, sizeof(uint32_t) * 256);
        if (std::equal(std::begin(temp_hash), std::end(temp_hash), std::begin(search_hash_pbkdf2)))
        {
            std::cout << "number-password=" << i << std::endl;
            memcpy(found_password, binary_passwords + 64 * i, sizeof(uint32_t) * 64);
            std::copy(bin_pass.begin(), bin_pass.end(), found_password);
            for (auto j = 0; j < 64; ++j)
            {
                std::cout << found_password[j];
            }
            std::cout << std::endl;
            std::cout << "searched_hash" << std::endl;
            for (auto j = 0; j < 256; ++j)
            {
                std::cout << temp_hash[j];
            }
            found_pass = true;
            break;
        }
        

    }
    auto t2 = std::chrono::high_resolution_clock::now();
    std::cout << "CPU time: "
        << std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1).count()
        << "ms" << std::endl;


    if (found_pass == false)
    {
        std::cout << "password not found" << std::endl;
    }*/
    //std::cout << std::endl;
    //std::cout << "Hashes" << std::endl;
    //for (auto i = 0; i < count_passwords * 256; ++i)
    //{

    //    if ((i % 256) == 0)
    //    {
    //        std::cout << std::endl;
    //        std::cout << "count i=" << i / (256) << " ";
    //        std::cout << pbkdf2_hash[i];
    //        // std::cout << std::endl;
    //    }
    //    else
    //    {
    //        std::cout << pbkdf2_hash[i];
    //    }


    ////    // std::cout << std::endl;
    //}
    //std::cout << std::endl;


    cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
        return 1;
    }
    cudaFree(dev_password_xor_with_ipad);
    cudaFree(dev_password_xor_with_opad);
    cudaFree(dev_pbkdf2_hash);
    cudaFree(dev_salt);
    cudaFree(dev_binary_password);

    return 0;
Error:
    cudaFree(dev_password_xor_with_ipad);
    cudaFree(dev_password_xor_with_opad);
    cudaFree(dev_pbkdf2_hash);
    cudaFree(dev_salt);
    cudaFree(dev_binary_password);


}
