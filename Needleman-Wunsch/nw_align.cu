
/*#include "cuda_runtime.h"
#include "device_launch_parameters.h"*/

#include <stdio.h>
#include <stdlib.h>

#define N 300

//typedef long long int ll;

__global__ void align(char *key , char *s , int *scores , int n , int num)
{
	int GAP = -1 , MATCH = 1 , MISMATCH = -1;
	int index = threadIdx.x + blockIdx.x * blockDim.x;
	if(index < num)
	{
		int i , j , k , dia , top , left;
		int dp[N + 1][N + 1];
		
		char r1[2*N+2] , r2[2*N+2];
		char traceback[N+1][N+1];
		for (i = 0; i <= n; i++)
		{
			dp[0][i] = GAP * i;
			dp[i][0] = GAP * i;
			traceback[0][i] = 'l';
			traceback[i][0] = 'u';
		}
		
		for (i = 1; i <= n; i++)
		{
			for (j = 1; j <= n; j++)
			{
				if(key[i-1] == s[n*index + j-1])
					dia = dp[i-1][j-1] + MATCH;
				else	
					dia = dp[i-1][j-1] + MISMATCH;
				top = dp[i-1][j] + GAP;
				left = dp[i][j-1] + GAP;
				dp[i][j] = dia > top ? (dia > left ? dia : left) : (top > left ? top : left);
				traceback[i][j] = dp[i][j] == dia ? 'd' : (dp[i][j] == top ? 'u' : 'l');
			}
		}
		/*
		for (i = 0; i <= n; i++)
		{
			for (j = 0; j <= n; j++)
			{
				printf("%d " , dp[i][j]);
			}
			printf("\n");
		}
		for (i = 1; i <= n; i++)
		{
			for (j = 1; j <= n; j++)
			{
				printf("%c " , traceback[i][j]);
			}
			printf("\n");
		}
		*/
		i = n , j = n , k = 0;
		while(!(i == 0 && j == 0))
		{
			if(traceback[i][j] == 'd')
			{
				r1[k] = key[i-1];
				r2[k] = s[n*index + j-1];
				i--; 
				j--;
			}
			else if(traceback[i][j] == 'u')
			{
				r1[k] = key[i-1];
				r2[k] = '-';
				i--;
			}
			else
			{
				r1[k] = '-';
				r2[k] = s[n*index + j-1];
				j--;
			}
			k++;
		}
		for(i = 0; i < k/2; i++)
		{
			r1[i] = (r1[i] + r1[k-i-1]) - (r1[k-i-1] = r1[i]);
			r2[i] = (r2[i] + r2[k-i-1]) - (r2[k-i-1] = r2[i]);
		}
		r1[k] = '\0';
		r2[k] = '\0';
		printf("\nAlignment #%d :\n%s\n%s\n" , index+1 , r1 , r2);
		int score = 0;
		for(i = 0; i < k; i++)
		{
			if(r1[k] == '-' || r2[k] == '-')
				score += GAP;
			else if(r1[i] == r2[i])
				score += MATCH;
			else
				score += MISMATCH;
		}
		scores[index] = score;
	}
}

int main(void)
{
	int size = sizeof(int);
	int THREADS = 1024;
	
	int *host_scores , *scores;
	int i , num , n;
	
	printf("Enter size:");
	scanf("%d" , &n);
	printf("Enter number of queries:");
	scanf("%d" , &num);
	
	int m = n < THREADS ? n : THREADS;
	
	char *host_key = (char *)malloc(n);
	char *tmp = (char *)malloc(n);
	char *host_q = (char *)malloc(num * n + 2);
	char *key , *q;
	
	printf("Enter key:");
	scanf("%s" , host_key);
	printf("Enter the queries:");
	for(i = 0; i <num; i++)
	{
		if(i == 0)
			scanf("%s" , host_q);
		else
		{
			scanf("%s" , tmp);
			strcat(host_q , tmp);
		}
	}
	
	host_scores = (int *)malloc(size * num);
	
	cudaMalloc((void **)&scores , num * size);
	cudaMalloc((void **)&key , n);
	cudaMalloc((void **)&q , n * num + 2);
	cudaMemcpy(key , host_key , n , cudaMemcpyHostToDevice);
	cudaMemcpy(q , host_q , n * num + 2 , cudaMemcpyHostToDevice);
	
	align <<<(n + m - 1) / m , m>>> (key , q , scores , n , num);

	cudaMemcpy(host_scores , scores , size * num , cudaMemcpyDeviceToHost);

	printf("\n\nAlignment Scores:\n");
	for(i = 0; i < num; i++)
		printf("Query #%d : %d\n" , i+1 , host_scores[i]);
	cudaFree(key);
	cudaFree(q);
	cudaFree(scores);
	return 0;
}