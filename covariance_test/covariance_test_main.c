#include <math.h>
#include <Windows.h>

// #include "covariance_samples.h"

// TODO: (sonictk) Get larger sample data and use it here
#define NUM_OF_SAMPLES 50000
// static const double xDataSet[] = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0, 25.0, 26.0, 27.0, 28.0, 29.0, 30.0, 31.0, 32.0};
// static const double yDataSet[] = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0, 25.0, 26.0, 27.0, 28.0, 29.0, 30.0, 31.0, 32.0};


// NOTE: (sonictk) x64 asm implementation
extern double correlation_sse(const double x[], const double y[], int n);
extern double correlation_avx(const double x[], const double y[], int n);


double correlation_ref(const double x[], const double y[], int n);

// NOTE: (sonictk) Reference implementation
double correlation_ref(const double x[], const double y[], int n)
{
    double sumX = 0.0;
    double sumY = 0.0;
    double sumXX = 0.0;
    double sumYY = 0.0;
    double sumXY = 0.0;

    for (int i=0; i < n; ++i) {
        sumX += x[i];
        sumY += y[i];
        sumXX += x[i] * x[i];
        sumYY += y[i] * y[i];
        sumXY += x[i] * y[i];
    }

    double covXY = (n * sumXY) - (sumX * sumY);
    double varX = (n * sumXX) - (sumX * sumX);
    double varY = (n * sumYY) - (sumY * sumY);

    return covXY / sqrt(varX * varY);
}


int main(int argc, char *argv[])
{
    srand(1);

    double xDataSet[NUM_OF_SAMPLES];
    double yDataSet[NUM_OF_SAMPLES];

    for (int i=0; i < NUM_OF_SAMPLES; ++i) {
        int xBaseVal = rand();
        int yBaseVal = rand();
        xDataSet[i] = (double)xBaseVal;
        yDataSet[i] = (double)yBaseVal;
    }

    LARGE_INTEGER startTimerValue;
    LARGE_INTEGER endTimerValue;
    LARGE_INTEGER timerFreq;

    QueryPerformanceFrequency(&timerFreq);
    QueryPerformanceCounter(&startTimerValue);

    double result = correlation_avx(xDataSet, yDataSet, NUM_OF_SAMPLES);

    QueryPerformanceCounter(&endTimerValue);

    double deltaTime = (double)(endTimerValue.QuadPart - startTimerValue.QuadPart * 1.0) / (double)timerFreq.QuadPart;

    printf("Time taken is: %f\nThe correlation is: %f\n", deltaTime, result);

    return 0;
}
