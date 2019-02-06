/**
	@author Kinjal Ray
	Date 06.01.19
	DNA Sequence alignment using Pointing Matrix
*/

#include <stdio.h>
#include <stdlib.h>

#define N 300

//typedef long long int ll;

__global__ void align(char *key , char *s , int *scores , int n , int num)
{
	const int GP = -1 , MR = 1;
	int index = threadIdx.x + blockIdx.x * blockDim.x;
	if(index < num)
	{
		int c_row = 1 , o_row , c_score;
		int sm[2][N+1];
		int pm[N+1][N+1];
		char r1[2*N+2] , r2[2*N+2];
		int i , j;
		/*Initialising Scoring Matrix*/
		for (i = 0; i <= n; i++)
		{
			sm[0][i] = GP * i;
			pm[0][i] = 1;
			pm[i][0] = 3;
		}
		pm[0][0] = 0;
		
		/*Filling the Pointing Matrix*/
		for(i = 1; i <= n; i++)
		{
			o_row = 1 - c_row;
			for(j = 1; j <= n; j++)
			{
				if(key[i-1] == s[n*index + j-1])
					c_score = MR;
				else
					c_score = GP;
				int max = sm[o_row][j-1] + c_score;
				int ptr = 2;
				if(max < sm[o_row][j] + GP)
				{
					max = sm[o_row][j] + GP;
					ptr = 3;
				}
				if(max < sm[c_row][j-1] + GP)
				{
					max = sm[c_row][j-1] + GP;
					ptr = 1;
				}
				sm[c_row][j] = max;
				pm[i][j] = ptr;
			}
			c_row = o_row;
		}
		
		/*for(i = 0; i <= n; i++)
		{
			for(j = 0; j <= n; j++)
			{
				printf("%d " , pm[i][j]);
			}
			printf("\n");
		}*/
		
		/*Sequence Alignment using Pointing Matrix*/
		int score = 0 , row = n , col = n;
		j = 0;
		//printf("PM : %d" , pm[row][col]);
		while(row >= 0 && col >= 0)//pm[row][col] != 0)
		{
			//printf("\nNOW %d %d %d\n" , row , col , pm[row][col]);
			if(row == 0 && col == 0)
				break;
			if(pm[row][col] == 3)
			{
				r1[j] = key[row-1];
				r2[j] = '-';
				row -= 1;
				score += GP;
			}
			else if(pm[row][col] == 1)
			{
				r1[j] = '-';
				r2[j] = s[n*index + col-1];
				col -= 1;
				score += GP;
			}
			else if(pm[row][col] == 2)
			{
				r1[j] = key[row-1];
				r2[j] = s[n*index + col-1];
				if(key[row-1] == s[n*index + col-1])
					score += MR;
				else
					score += GP;
				row -= 1;
				col -= 1;
			}
			else
				score += GP;
			j += 1;
		}
		
		/*for(i = 0; i < j/2; i++)
		{
			r1[i] = (r1[i] + r1[j-i-1]) - (r1[j-i-1] = r1[i]);
			r2[i] = (r2[i] + r2[j-i-1]) - (r2[j-i-1] = r2[i]);
		} */
		
		r1[j] = '\0';
		r2[j] = '\0';
		printf("\nAlignment #%d :\n-------------------\nKey:\n%s\nQuery:\n%s\n" , index+1 , r1 , r2);
		
		scores[index] = score;
	}
}

int main(int argc, char** argv)
{
	int size = sizeof(int);
	int THREADS = 1024;
	
	freopen(argv[1] , "r", stdin);
	freopen(argv[2] , "w", stdout);
	
	int *host_scores , *scores;
	int i , num , n;
	
	//printf("Enter size:");
	scanf("%d" , &n);
	//printf("Enter number of queries:");
	scanf("%d" , &num);
	
	int m = num < THREADS ? num : THREADS;
	
	char *host_key = (char *)malloc(n);
	char *tmp = (char *)malloc(n);
	char *host_q = (char *)malloc(num * n + 2);
	char *key , *q;
	
	//printf("Enter key:");
	scanf("%s" , host_key);
	//printf("Enter the queries:");
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

	printf("\n\nAlignment Scores:\n----------------------------\n");
	for(i = 0; i < num; i++)
		printf("Query #%d : %d\n" , i+1 , host_scores[i]);
	cudaFree(key);
	cudaFree(q);
	cudaFree(scores);
	return 0;
}