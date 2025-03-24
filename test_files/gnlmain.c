#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

char *get_next_line(int fd);

int main(int argc, char **argv)
{
	if (argc == 2)
	{
		int	fd = open(argv[1], O_RDONLY);
		if (fd < 0)
		{
			printf("open function error\n");
			return (0);
		}
		char *line;
		line = get_next_line(fd);
		while (line)
		{
			printf("%s", line);
			free(line);
			line = get_next_line(fd);
		}
		close(fd);
		return (0);
	}
	else
	{
		int	fd1 = open(argv[1], O_RDONLY);
		int	fd2 = open(argv[2], O_RDONLY);
		int	fd3 = open(argv[3], O_RDONLY);
		int	fd4 = open(argv[4], O_RDONLY);
		if (fd1 < 0 || fd2 < 0 || fd3 < 0 || fd4 < 0)
		{
			printf("open function error\n");
			return (0);
		}
		char *line;
		line = get_next_line(fd1); 
		printf("%s", line);
		free(line);
		line = get_next_line(fd2);
		printf("%s", line);
		free(line);
		line = get_next_line(fd3);
		printf("%s", line);
		free(line);
		line = get_next_line(fd4);
		printf("%s", line);
		free(line);
		line = get_next_line(fd1); 
		printf("%s", line);
		free(line);
		line = get_next_line(fd2);
		printf("%s", line);
		free(line);
		line = get_next_line(fd3);
		printf("%s", line);
		free(line);
		line = get_next_line(fd4);
		printf("%s", line);
		free(line);
		close(fd1);
		close(fd2);
		close(fd3);
		close(fd4);
		return (0);
	}
}
