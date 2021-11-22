#include "cuda_runtime.h"
#include "device_launch_parameters.h"
//#include "HMAC-SHA256.cpp"
#include <stdio.h>
#include <time.h>
#include <iostream>
#include <openssl/hmac.h>
#include <openssl/evp.h>
#include <string>
#include <fstream>

#define N 2048
#define M 2048


#define uchar unsigned char
#define uint unsigned int

#define DBL_INT_ADD(a,b,c) if (a > 0xffffffff - (c)) ++b; a += c;
#define ROTLEFT(a,b) (((a) << (b)) | ((a) >> (32-(b))))
#define ROTRIGHT(a,b) (((a) >> (b)) | ((a) << (32-(b))))

#define CH(x,y,z) (((x) & (y)) ^ (~(x) & (z)))
#define MAJ(x,y,z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define EP0(x) (ROTRIGHT(x,2) ^ ROTRIGHT(x,13) ^ ROTRIGHT(x,22))
#define EP1(x) (ROTRIGHT(x,6) ^ ROTRIGHT(x,11) ^ ROTRIGHT(x,25))
#define SIG0(x) (ROTRIGHT(x,7) ^ ROTRIGHT(x,18) ^ ((x) >> 3))
#define SIG1(x) (ROTRIGHT(x,17) ^ ROTRIGHT(x,19) ^ ((x) >> 10))

typedef struct {
    uchar data[64];
    uint datalen;
    uint bitlen[2];
    uint state[8];
} SHA256_CTX;

uint k[64] = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

__device__ void SHA256Transform(SHA256_CTX* ctx, uchar data[])
{
    uint a, b, c, d, e, f, g, h, i, j, t1, t2, m[64];

    for (i = 0, j = 0; i < 16; ++i, j += 4)
        m[i] = (data[j] << 24) | (data[j + 1] << 16) | (data[j + 2] << 8) | (data[j + 3]);
    for (; i < 64; ++i)
        m[i] = SIG1(m[i - 2]) + m[i - 7] + SIG0(m[i - 15]) + m[i - 16];

    a = ctx->state[0];
    b = ctx->state[1];
    c = ctx->state[2];
    d = ctx->state[3];
    e = ctx->state[4];
    f = ctx->state[5];
    g = ctx->state[6];
    h = ctx->state[7];

    for (i = 0; i < 64; ++i) {
        t1 = h + EP1(e) + CH(e, f, g) + k[i] + m[i];
        t2 = EP0(a) + MAJ(a, b, c);
        h = g;
        g = f;
        f = e;
        e = d + t1;
        d = c;
        c = b;
        b = a;
        a = t1 + t2;
    }

    ctx->state[0] += a;
    ctx->state[1] += b;
    ctx->state[2] += c;
    ctx->state[3] += d;
    ctx->state[4] += e;
    ctx->state[5] += f;
    ctx->state[6] += g;
    ctx->state[7] += h;
}

__device__ void SHA256Init(SHA256_CTX* ctx)
{
    ctx->datalen = 0;
    ctx->bitlen[0] = 0;
    ctx->bitlen[1] = 0;
    ctx->state[0] = 0x6a09e667;
    ctx->state[1] = 0xbb67ae85;
    ctx->state[2] = 0x3c6ef372;
    ctx->state[3] = 0xa54ff53a;
    ctx->state[4] = 0x510e527f;
    ctx->state[5] = 0x9b05688c;
    ctx->state[6] = 0x1f83d9ab;
    ctx->state[7] = 0x5be0cd19;
}

__device__ void SHA256Update(SHA256_CTX* ctx, uchar data[], uint len)
{
    for (uint i = 0; i < len; ++i) {
        ctx->data[ctx->datalen] = data[i];
        ctx->datalen++;
        if (ctx->datalen == 64) {
            SHA256Transform(ctx, ctx->data);
            DBL_INT_ADD(ctx->bitlen[0], ctx->bitlen[1], 512);
            ctx->datalen = 0;
        }
    }
}

__device__ void SHA256Final(SHA256_CTX* ctx, uchar hash[])
{
    uint i = ctx->datalen;

    if (ctx->datalen < 56) {
        ctx->data[i++] = 0x80;
        while (i < 56)
            ctx->data[i++] = 0x00;
    }
    else {
        ctx->data[i++] = 0x80;
        while (i < 64)
            ctx->data[i++] = 0x00;
        SHA256Transform(ctx, ctx->data);
        memset(ctx->data, 0, 56);
    }

    DBL_INT_ADD(ctx->bitlen[0], ctx->bitlen[1], ctx->datalen * 8);
    ctx->data[63] = ctx->bitlen[0];
    ctx->data[62] = ctx->bitlen[0] >> 8;
    ctx->data[61] = ctx->bitlen[0] >> 16;
    ctx->data[60] = ctx->bitlen[0] >> 24;
    ctx->data[59] = ctx->bitlen[1];
    ctx->data[58] = ctx->bitlen[1] >> 8;
    ctx->data[57] = ctx->bitlen[1] >> 16;
    ctx->data[56] = ctx->bitlen[1] >> 24;
    SHA256Transform(ctx, ctx->data);

    for (i = 0; i < 4; ++i) {
        hash[i] = (ctx->state[0] >> (24 - i * 8)) & 0x000000ff;
        hash[i + 4] = (ctx->state[1] >> (24 - i * 8)) & 0x000000ff;
        hash[i + 8] = (ctx->state[2] >> (24 - i * 8)) & 0x000000ff;
        hash[i + 12] = (ctx->state[3] >> (24 - i * 8)) & 0x000000ff;
        hash[i + 16] = (ctx->state[4] >> (24 - i * 8)) & 0x000000ff;
        hash[i + 20] = (ctx->state[5] >> (24 - i * 8)) & 0x000000ff;
        hash[i + 24] = (ctx->state[6] >> (24 - i * 8)) & 0x000000ff;
        hash[i + 28] = (ctx->state[7] >> (24 - i * 8)) & 0x000000ff;
    }
}

__device__ char* SHA256(unsigned char* data) {
    int strLen = strlen((char*)data);
    SHA256_CTX ctx;
    unsigned char hash[32];
    char* hashStr = malloc(65);
    strcpy(hashStr, "");

    SHA256Init(&ctx);
    SHA256Update(&ctx, data, strLen);
    SHA256Final(&ctx, hash);

    char s[3];
    for (int i = 0; i < 32; i++) {
        sprintf(s, "%02x", hash[i]);
        strcat(hashStr, s);
    }

    return hashStr;
}


cudaError_t addWithCuda(std::string passwords, unsigned char* salt, int length_salt, int iterations, int length_hash, unsigned char* hash_output, unsigned char* pass_output);
//cudaError_t readWithCuda(std::ifstream file, std::string )


__global__ void addKernel(char* passwords, unsigned char* salt, int length_salt, int iterations, int length_hash, unsigned char* hash_output, unsigned char* pass_output)
{
    
    
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    
    //PKCS5_PBKDF2_HMAC(&passwords[i], strlen(&passwords[i]), salt, strlen((char*)salt), iterations, EVP_sha256(), length_hash, &hash_output[length_hash]);
    
    //pbkdf2_hmac_sha256(i, passwords, salt, length_salt, iterations, length_hash, hash_output, pass_output);
    //PKCS5_PBKDF2_HMAC(password, strlen(password), salt, strlen((char*)salt), 4096, EVP_sha256(), i, hash_output);
    //PKCS5_PBKDF2_HMAC(password, strlen(password), salt, strlen((char*)salt), 4096, EVP_sha256(), i, hash_output);
    //PKCS5_PBKDF2_HMAC(password, strlen(password), salt, strlen((char*)salt), 4096, EVP_sha256(), i, hash_output);
    //PKCS5_PBKDF2_HMAC(password, strlen(password), salt, strlen((char*)salt), 4096, EVP_sha256(), i, hash_output);
    //PKCS5_PBKDF2_HMAC(password, strlen(password), salt, strlen((char*)salt), 4096, EVP_sha256(), i, hash_output);
}

//__global__ void read_from_file(std::ifstream file)

int main()
{
    /*const int arraySize = 5;
    const int a[arraySize] = { 1, 2, 3, 4, 5 };
    const int b[arraySize] = { 10, 20, 30, 40, 50 };
    int c[arraySize] = { 0 };*/
    //const int N = 2048; //блоков
    //const int M = 2048; //потоков
    //длина хеша
    unsigned char hash_unknowed_password[] = "127198299418516314213416115420814586671341501494113814733145806219619820859207235214206";
    const int hash_length = 32;
    unsigned char* output_pass;
    unsigned char salt[] = "POINT";
    //unsigned char *password;
    //int iterations = 4096;
    unsigned char hash_output[hash_length];
    std::ifstream file_of_passwords;
    file_of_passwords.open("E:\\repos\\9mil.txt");
    std::string passwords;
    std::string pass;
    if (passwords.empty()) 
    {
        while (!file_of_passwords.eof())
        {
            file_of_passwords >> pass;
            passwords.append(pass);
        }
    }
    //std::cout << passwords << std::endl;
    // Add vectors in parallel.
    cudaError_t cudaStatus;

    while (hash_output != hash_unknowed_password)
    {
        
        cudaStatus = addWithCuda(passwords, salt, strlen((char*)salt), 4096, hash_length, hash_output, output_pass);
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "addWithCuda failed!");
            return 1;
        }
    }
    std::cout << output_pass << std::endl;
    /*printf("{1,2,3,4,5} + {10,20,30,40,50} = {%d,%d,%d,%d,%d}\n",
        c[0], c[1], c[2], c[3], c[4]);*/

    // cudaDeviceReset must be called before exiting in order for profiling and
    // tracing tools such as Nsight and Visual Profiler to show complete traces.
    cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
        return 1;
    }

    return 0;
}

// Helper function for using CUDA to add vectors in parallel.
cudaError_t addWithCuda(std::string passwords, unsigned char* salt, int length_salt, int iterations, int length_hash, unsigned char* hash_output, unsigned char* pass_output)
{

    //const int len_of_hash = 32;
    unsigned char *temp_hash_output;
    //const char password[] = "12345";
    unsigned char *temp_salt;
    //char* passwords;
    char* temp_passwords;
    char* temp_passwords_for_string;
    unsigned char* temp_pass_output;
    std::copy(passwords.begin(), passwords.end(), temp_passwords_for_string);
    //std::ifstream file_of_passwords;

    //std::cout << strlen((char*)salt) << std::endl;

   

    //std::cout << "\n" << std::endl;
    //std::cout << "Hello World!\n";
    //return *hash;

    /*int* dev_a = 0;
    int* dev_b = 0;
    int* dev_c = 0;*/
    cudaError_t cudaStatus;

    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    // Allocate GPU buffers for three vectors (two input, one output)    .
    cudaStatus = cudaMalloc((void**)&temp_salt, length_salt * sizeof(unsigned char));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&temp_passwords, strlen(temp_passwords) * sizeof(char));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&temp_hash_output, length_hash * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&temp_passwords, strlen(temp_passwords) * sizeof(char));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    // Copy input vectors from host memory to GPU buffers.
    cudaStatus = cudaMemcpy(temp_salt, salt, length_salt * sizeof(unsigned char), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(temp_passwords, temp_passwords_for_string, strlen(temp_passwords_for_string) * sizeof(char), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(temp_hash_output, hash_output, strlen((char*)hash_output) * sizeof(unsigned char), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(temp_pass_output, pass_output, strlen((char*)pass_output) * sizeof(unsigned char), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    /*cudaStatus = cudaMemcpy(temp_hash_output, , size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }*/

    // Launch a kernel on the GPU with one thread for each element.

    addKernel <<<N, M >>> (temp_passwords, temp_salt, length_salt, iterations, length_hash, temp_hash_output, temp_pass_output);

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
    cudaStatus = cudaMemcpy(hash_output, temp_hash_output, length_hash * sizeof(unsigned char), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(pass_output, temp_pass_output, length_hash * sizeof(unsigned char), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

Error:
    cudaFree(temp_hash_output);
    cudaFree(temp_salt);
    cudaFree(temp_passwords);
    return cudaStatus;
}

//__host__ __location__(device) int PKCS5_PBKDF2_HMAC(const char* pass, int passlen, const unsigned char* salt, int saltlen, int iter, const EVP_MD* digest, int keylen, unsigned char* out)
//{
//    return PKCS5_PBKDF2_HMAC(pass, passlen, salt, saltlen, iter, digest, keylen, out);
//}
//
//__host__ __location__(device)size_t strlen(const char* arr)
//{
//    return strlen(arr);
//}
//
//__host__ __location__(device)EVP_MD* EVP_sha256(void)
//{
//    return nullptr;
//}


//__host__ __device__ int PKCS5_PBKDF2_HMAC(const char* pass, int passlen, const unsigned char* salt, int saltlen, int iter, const EVP_MD* digest, int keylen, unsigned char* out)
//{
//    return int();
//}
//
//__host__ __device__ size_t strlen(const char*)
//{
//    return size_t();
//}
//
//__host__ __device__ const EVP_MD* EVP_sha256(void)
//{
//    return nullptr;
//}




