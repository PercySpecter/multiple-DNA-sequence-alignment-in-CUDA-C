
//TTACTG
//ATTGCG

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>


typedef long long int ll;

void align(char *key , char *s , ll *scores , ll n , ll num , ll index)
{
	ll N = 500;
	int GAP = -1 , MATCH = 1 , MISMATCH = -1;
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
		printf("\nAlignment #%d :\n-------------------\nKey:\n%s\nQuery:\n%s\n" , index+1 , r1 , r2);

		scores[index] = dp[n][n];
}

int main()
{
	ll n , num , i;
	//printf("Enter size:");
	scanf("%lld" , &n);
	//printf("Enter number of queries:");
	scanf("%lld" , &num);
	char *s = (char *)malloc(num * n + 2);
	char *key = (char *)malloc(n);
	char *tmp = (char *)malloc(n);
	ll *scores = (ll *)malloc(num * sizeof(ll));
	//printf("Enter key:");
	scanf("%s" , key);
	//printf("Enter queries:");
	for(i = 0; i < num; i++)
	{
		if(i == 0)
		{
			scanf("%s" , s);
			continue;
		}
		scanf("%s" , tmp);
		strcat(s , tmp);
	}
	
	struct timespec start, end;
	clock_gettime(CLOCK_MONOTONIC_RAW, &start);
	for(i = 0; i < num; i++)
	{
		align(key , s , scores , n , num , i);
	}
	clock_gettime(CLOCK_MONOTONIC_RAW, &end);
	uint64_t delta_us = (end.tv_sec - start.tv_sec) * 1000000 + (end.tv_nsec - start.tv_nsec) / 1000;
	printf("TIME : %ulld" , delta_us);
	
	printf("\nResults:\n");
	for(i = 0; i < num; i++)
		printf("Query %lld : %lld\n" , (i + 1) , scores[i]);
	return 0;
}
