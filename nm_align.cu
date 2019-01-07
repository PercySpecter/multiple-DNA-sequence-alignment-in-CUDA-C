
#include <stdio.h>
#include <stdlib.h>

#define N 30

//typedef long long int ll;

__global__ void align(char *key , char *s , int *scores , int n , int num)
{
	int GP = -1 , MR = 1;
	int index = threadIdx.x + blockIdx.x * blockDim.x;
	if(index < num)
	{
		int i , j , k , tmp;
		int nm[N + 1][N + 1];
		
		char r1[2*N+2] , r2[2*N+2];
		for (i = 0; i <= n; i++)
		{
			nm[0][i] = GP * i;
			nm[i][0] = GP * i;
		}
		
		for (i = 1; i <= n; i++)
		{
			for (j = 1; j <= n; j++)
			{
				if(key[i-1] == s[n*index + j-1])
					nm[i][j] = nm[i-1][j-1] + MR;
				else	
				{
					if(nm[i-1][j] <= nm[i][j-1])
						nm[i][j] = nm[i][j-1] + GP;
					else
						nm[i][j] = nm[i-1][j] + GP;
				}
			}
		}
		
		/* for (i = 0; i <= n; i++)
		{
			for (j = 0; j <= n; j++)
			{
				printf("%d " , nm[i][j]);
			}
			printf("\n");
		} */
		
		i = n , j = n , k = 0;
		//for(int cnt = 1; cnt <= 30 && i > 0 && j > 0; cnt++)
		while(i > 0 && j > 0)
		{
			//if(index == 3)printf("**%d %d % d\n" , cnt , i , j);
			tmp = nm[i-1][j-1] > nm[i][j-1] ? (nm[i-1][j-1] > nm[i-1][j] ? nm[i-1][j-1] : nm[i-1][j]) : (nm[i][j-1] > nm[i-1][j] ? nm[i][j-1] : nm[i-1][j]);
			if(tmp == nm[i-1][j-1] || key[i] == s[n*index + j-1])
			{
				r1[k] = key[i-1];
				r2[k] = s[n*index + j-1];
				i--;
				j--;
			}
			else if(tmp == nm[i][j-1])
			{
				r1[k] = '-';
				r2[k] = s[n*index + j-1];
				j--;
			}
			else if(tmp == nm[i-1][j])
			{
				r1[k] = key[i-1];
				r2[k] = '-';
				i--;
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
		printf("\nAlignment #%d :\n-------------------\nKey:\n%s\nQuery:\n%s\n" , index+1 , r1 , r2);
		int score = 0;
		for(i = 0; i < k; i++)
		{
			if(r1[k] == '-' || r2[k] == '-')
				score += GP;
			else if(r1[i] == r2[i])
				score += MR;
			else
				score += GP;
		}
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