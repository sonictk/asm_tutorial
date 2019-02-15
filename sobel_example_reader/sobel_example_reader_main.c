#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <Windows.h>


#define STB_IMAGE_IMPLEMENTATION // NOTE: (sonictk) Necessary for usage for ``stb_image.h``
#include <stb/stb_image.h>

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include <stb/stb_image_write.h>

// NOTE: (sonictk) ``data`` needs to be grayscale image, single 8 bit value
// ``a`` is ptr to start of image data, ``b`` is current row and ``c`` is current column
// Thus ``I`` is a convenience macro to get the image data for the current row and column
#define I(a, b, c) a[(b) * (cols) + (c)]

void sobel_ref(unsigned char *data, float *out, long rows, long cols)
{
    int r;
    int c;
    int gx;
    int gy;

    for (r = 1; r < rows - 1; r++) {
        for (c = 1; c < cols - 1; c++) {
            gx = -I(data, r - 1, c - 1) + I(data, r - 1, c + 1) +
                -2 * I(data, r, c - 1) + 2 * I(data, r, c + 1) +
                -I(data, r + 1, c - 1) + I(data, r + 1, c + 1);

            gy = -I(data, r - 1, c - 1) - 2 * I(data, r - 1, c) - I(data, r - 1, c + 1) +
                 I(data, r + 1, c - 1) + 2 * I(data, r + 1, c) + I(data, r + 1, c + 1);

            float val = sqrt(((float)(gx) * (float)(gx)) + ((float)(gy) * (float)(gy)));
            I(out, r, c) = sqrt(((float)(gx) * (float)(gx)) + ((float)(gy) * (float)(gy)));
        }
    }
}


// TODO: (sonictk) asm verison is still wrong somehow
extern void sobel(unsigned char *data, float *out, long rows, long columns);


// NOTE: (sonictk) Globals
static const char PNG_FILE_EXT[] = "png";


int main(int argc, char *argv[])
{
    if (argc == 1) {
        perror("You need to specify an image to read!");

        return 0;
    }

    HANDLE processHeap = GetProcessHeap();
    if (processHeap == NULL) {
        perror("Unable to accquire handle to heap for process!");

        return 1;
    }

    for (int i=1; i < argc; ++i) {
        char *pngFilePath = argv[i];

        size_t filePathLen = strlen(pngFilePath);

        if (filePathLen < 3) {
            perror("File path specified was invalid!");

            return 0;
        }

        FILE *imgFileHandle = fopen(pngFilePath, "r");
        if (imgFileHandle == NULL) {
            fprintf(stderr, "The file: %s was not accessible! Does it exist?", pngFilePath);

            return 0;
        }

        int imgWidth = -1;
        int imgHeight = -1;
        int imgBitsPerPixel = -1;
        unsigned char *imgData = stbi_load(pngFilePath,
                                           &imgWidth,
                                           &imgHeight,
                                           &imgBitsPerPixel,
                                           4);

        // NOTE: (sonictk) Process colour image into greyscale values. Here we
        // just use simple average.
        uint8_t *imgDataGreyscale = (uint8_t *)HeapAlloc(processHeap, HEAP_ZERO_MEMORY, imgWidth * imgHeight * sizeof(uint8_t));
        int pIdx = 0;
        for (int r=0; r < imgHeight; ++r) {
            for (int c=0; c < imgWidth; ++c) {
                unsigned char rVal = imgData[pIdx];
                unsigned char gVal = imgData[pIdx + 1];
                unsigned char bVal = imgData[pIdx + 2];

                uint8_t greyscaleVal = (rVal + gVal + bVal) / 3;
                imgDataGreyscale[r * imgWidth + c] = greyscaleVal;

                pIdx += 4;
            }
        }

        float *imgProcessed = (float *)HeapAlloc(processHeap, HEAP_ZERO_MEMORY, imgWidth * imgHeight * sizeof(float));

        LARGE_INTEGER startTimerValue;
        LARGE_INTEGER endTimerValue;
        LARGE_INTEGER timerFreq;

        QueryPerformanceFrequency(&timerFreq);
        QueryPerformanceCounter(&startTimerValue);

        // NOTE: (sonictk) Convolution kernels are 3x3 matrices, so the final image
        // cannnot have its first/last rows/columns calculated, thus final output
        // size is smaller.
        sobel(imgDataGreyscale, imgProcessed, imgHeight, imgWidth);

        QueryPerformanceCounter(&endTimerValue);

        double deltaTime = (double)(endTimerValue.QuadPart - startTimerValue.QuadPart * 1.0) / (double)timerFreq.QuadPart;

        printf("Time taken for sobel is: %f", deltaTime);

        uint8_t *finalOutputData = (uint8_t *)HeapAlloc(processHeap, HEAP_ZERO_MEMORY, (imgWidth - 2) * (imgHeight - 2) * sizeof(uint8_t) * 4);

        int pixelIdx = 0;
        for (int r=1; r < imgHeight - 1; ++r) {
            for (int c=1; c < imgWidth - 1; ++c) {
                float val = imgProcessed[r * imgWidth + c];

                finalOutputData[pixelIdx] = (uint8_t)val;
                finalOutputData[pixelIdx + 1] = (uint8_t)val;
                finalOutputData[pixelIdx + 2] = (uint8_t)val;
                finalOutputData[pixelIdx + 3] = 255;

                pixelIdx += 4;
            }
        }

        char outputPngFilePath[512];
        sprintf(outputPngFilePath, "%s_output.png", pngFilePath);

        stbi_write_png(outputPngFilePath, imgWidth - 2, imgHeight - 2, 4, finalOutputData, (imgWidth - 2) * 4);

        BOOL stat = HeapFree(processHeap, 0, imgProcessed);
        if (stat == 0) {
            perror("Failed to deallocate memory for processed image data!");

            return 1;
        }

        stat = HeapFree(processHeap, 0, finalOutputData);
        if (stat == 0) {
            perror("Failed to deallocate memory for final image data!");

            return 1;
        }

        stbi_image_free(imgData);
    }

    return 0;
}
