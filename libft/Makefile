SRC = ft_abs.c \
	  ft_adtoa.c \
	  ft_atoi.c \
	  ft_bitstoa.c \
	  ft_bzero.c \
	  ft_isalnum.c \
	  ft_isalpha.c \
	  ft_isascii.c \
	  ft_isblank.c \
	  ft_isdigit.c \
	  ft_isinvis.c \
	  ft_islower.c \
	  ft_isprint.c \
	  ft_isupper.c \
	  ft_itoa.c \
	  ft_log.c \
	  ft_lstadd.c \
	  ft_lstcontdel.c \
	  ft_lstdel.c \
	  ft_lstdelone.c \
	  ft_lstiter.c \
	  ft_lstmap.c \
	  ft_lstnew.c \
	  ft_max.c \
	  ft_memalloc.c \
	  ft_memccpy.c \
	  ft_memchr.c \
	  ft_memcmp.c \
	  ft_memcpy.c \
	  ft_memdel.c \
	  ft_memdup.c \
	  ft_memmove.c \
	  ft_memset.c \
	  ft_min.c \
	  ft_pow.c \
	  ft_print_bits.c \
	  ft_print_memory.c \
	  ft_putchar.c \
	  ft_putchar_fd.c \
	  ft_putendl.c \
	  ft_putendl_fd.c \
	  ft_putnbr.c \
	  ft_putnbr_fd.c \
	  ft_putstr.c \
	  ft_putstr_fd.c \
	  ft_realloc.c \
	  ft_strcat.c \
	  ft_strchr.c \
	  ft_strclr.c \
	  ft_strcmp.c \
	  ft_strcpy.c \
	  ft_strdel.c \
	  ft_strdup.c \
	  ft_strequ.c \
	  ft_striter.c \
	  ft_striteri.c \
	  ft_strjoin.c \
	  ft_strlcat.c \
	  ft_strlen.c \
	  ft_strmap.c \
	  ft_strmapi.c \
	  ft_strncat.c \
	  ft_strncmp.c \
	  ft_strncpy.c \
	  ft_strnequ.c \
	  ft_strnew.c \
	  ft_strnstr.c \
	  ft_strrchr.c \
	  ft_strsplit.c \
	  ft_strstr.c \
	  ft_strsub.c \
	  ft_strtrim.c \
	  ft_tolower.c \
	  ft_toupper.c \
	  ft_toprint.c \
	  ft_ulog.c \
	  ft_umin.c \
	  ft_umax.c

NAME = libft.a
FLAGS = -Wall -Wextra -Werror

OBJ = $(SRC:.c=.o)

CC = gcc
RM = @rm -fv
.PHONY: all, clean, fclean, re

all: $(NAME)

$(NAME): $(OBJ) libft.h Makefile
	ar -rc $(NAME) $(OBJ)
	ranlib $(NAME)

%.o:%.c
	$(CC) $(FLAGS) -c $<

clean:
	@echo "Cleaning objects:"
	$(RM) $(OBJ)

fclean: clean
	@echo "Cleaning library:"
	$(RM) $(NAME)

re: fclean all
