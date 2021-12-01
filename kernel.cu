
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <string>
#include <bitset>
#include <iostream>
//#include <vector>
#include <thrust/host_vector.h>
#include <thrust/copy.h>


/*auto h0 = 0x6a09e667;
    auto  h1 = 0xbb67ae85;
    auto  h2 = 0x3c6ef372;
    auto  h3 = 0xa54ff53a;
    auto  h4 = 0x510e527f;
    auto  h5 = 0x9b05688c;
    auto  h6 = 0x1f83d9ab;
    auto  h7 = 0x5be0cd19;
    int round_consts[64] = { 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
                            0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
                            0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
                            0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
                            0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
                            0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
                            0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
                            0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2 };

    int index = threadIdx.x;
    int w[64] = {};*/

cudaError_t addWithCuda(char* binary_pass, int length_block);

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
    for (auto i = 0; i < 512; ++i)
    {
        std::cout << binary_str[i];
    }
    std::cout << std::endl;
    std::cout << sizeof(binary_str) << std::endl;
    return binary_str;
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
    delete[] binary_str;
    delete[] ipad;
}

__device__ int* password_xor_with_OPAD(char* password, int length)
{
    int* binary_str = new int[512]{ 0 };
    int OPAD [] = { 0,1,0,1,1,1,0,0 };
    int* opad = new int[512]{ 0 };
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

 __host__ void preparation_sha256_with_IPAD(__int64* password_xor_with_ipad, __int64*prev_hash)
{
     __int64* binary_str = new __int64[1024]{ 0 };

    //memcpy(binary_str, password_xor_with_ipad, 512);
    std::cout << std::endl;
    for (auto i = 0; i < 512; ++i)
    {
        std::cout << password_xor_with_ipad[i];
    }
    std::cout << std::endl;

    memcpy(binary_str, password_xor_with_ipad, 8 * 512);
    binary_str[769] = 1;
    binary_str[1014] = 1;
    binary_str[1015] = 1;
    //memmove(binary_str, password_xor_with_ipad, 512);
    for (auto i = 0; i < 1024; ++i)
    {
        std::cout << binary_str[i];
    }
    std::cout << std::endl;
   /* memmove(binary_str+256, prev_hash, 256);
    for (auto i = 0; i < 1024; ++i)
    {
        std::cout << binary_str[i];
    }*/

    //std::string binary_str = password_xor_with_ipad;
    //std::string binary_Ui = {};
    //for (auto i = 0; i < Ui.size(); ++i)
    //{
    //    binary_Ui.append(std::bitset<8>(Ui.c_str()[i]).to_string());
    //}
    //binary_str = binary_str + binary_Ui;//512+256 bits=768bits
    //int size_binary_str = binary_str.size();//length of input message (pass xor OPAD)||U(i-1))
    //binary_str.append("1"); //add 1 bit =769 bit
    //for (auto i = 0; i < 191; ++i) // add '0' multiple 512 => 769+191=960 mod 512 = 448 mod 512
    //{
    //    binary_str.append("0");
    //}
    //std::vector<int>length_pass_in_binary = {};//binary vector of size input message  
    //int bit=0;
    ////size_t number_of_bits_password = binary_.size();
    //while (size_binary_str != 0)
    //{
    //    bit = size_binary_str % 2 ? 1 : 0;
    //    length_pass_in_binary.push_back(bit);
    //    size_binary_str /= 2;
    //}
    //for (auto i = 0; i < 64 - length_pass_in_binary.size(); ++i)//add last 64 bits, where 64 - length_pass_in_binary '0'
    //{
    //    binary_str.append("0");
    //}
    //for (auto i = 0; i < length_pass_in_binary.size(); ++i)//add binary vector of value input message
    //{
    //   binary_str.push_back((char)(length_pass_in_binary[length_pass_in_binary.size() - 1 - i]) + 48);
    //}

    //// std::cout << hash_output.size() << std::endl;
    //// char* bin_str_512 = (char*)malloc(hash_output.size());
    //for (auto i : binary_str)//output 1024 binary message
    //{
    //    std::cout << i;
    //}
    //std::cout << std::endl;
    //char **w = new char*[64];
    //for (auto i = 0; i < 64; ++i)
    //    w[i] = new char[32];
    //
    //// thrust::copy(hash_output.begin(), hash_output.end(), &bin_str_512[0]);
    ////std::string message_schedule[64];
    ////for (auto i = 0; i < 64; ++i)
    ////{
    ////    if (i < 16)
    ////    {
    ////        for (auto j = 0; j < 32; ++j)
    ////        {
    ////            message_schedule[i] += pass[j + 32 * i];
    ////        }
    ////    }
    ////    else
    ////    {
    ////        for (auto j = 0; j < 32; ++j)
    ////        {
    ////            message_schedule[i] += '0';
    ////        }
    ////    }
    ////}
    ////for (auto i : message_schedule)
    ////{
    ////    std::cout << i << std::endl;
    ////}
    ////std::cout << std::endl;
    ////char message_schedule_d[64][32];
    //int count=0;
    //for (auto i = 0; i < 64; ++i)
    //{
    //    for (auto j = 0; j < 32; ++j)
    //    {
    //        //std::cout << i << " " << j << std::endl;
    //        w[i][j] = binary_str[count];
    //        count++;
    //    }
    //    count++;
    //}
    //for (auto i = 0; i < 64; ++i)
    //{
    //    for (auto j = 0; j < 32; ++j)
    //    {
    //        std::cout << w[i][j];
    //    }
    //    std::cout << std::endl;
    //}
    //return w;
}

 __host__ void preparation_sha256_with_OPAD(__int64* password_xor_with_opad, __int64* hash)
 {
     __int64* binary_str = new __int64[1024]{ 0 };

     //memcpy(binary_str, password_xor_with_ipad, 512);
     std::cout << std::endl;
     for (auto i = 0; i < 512; ++i)
     {
         std::cout << password_xor_with_opad[i];
     }
     std::cout << std::endl;

     memcpy(binary_str, password_xor_with_opad, 8 * 512);
     binary_str[768] = 1;
     binary_str[1014] = 1;
     binary_str[1015] = 1;
     memcpy(binary_str + 512, hash, 8 * 256);
     //memmove(binary_str, password_xor_with_ipad, 512);
     for (auto i = 0; i < 1024; ++i)
     {
         std::cout << binary_str[i];
     }
     std::cout << std::endl;
 }

__global__ void addKernel(char* binary_pass, int length_block)
{
    
    


}
int main()
{
   
    std::string password = "1234";
    __int64* password_xor_with_ipad = password_xor_with_IPAD("1234", 4);
    __int64* prev_hash_u = new __int64[256]{ 0 };
    preparation_sha256_with_OPAD(password_xor_with_ipad, prev_hash_u);
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
    cudaStatus = cudaMalloc((void**)&dev_binary_pass, length_block * sizeof(char));
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
    addKernel << <16, 16 >> > (dev_binary_pass, length_block);

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
