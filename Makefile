FILES = main.c \
		read_scene.c \
		read_xml.c \
		parse_nodes.c \
		parse.c \
		init.c \
		util.c \
		gen_matricies.c \
		loop_hook.c \
		key_hooks.c \
		mouse_hooks.c \
		hooks.c \
		load_opencl.c \
		display_opencl.c \
		hash_map.c \
		hash_map2.c \
		buf_handler.c

CFLAGS = -Llibgxns -lgxns -framework OpenGL -framework AppKit -framework OpenCL
FLAGS = -Wall -Wextra -Werror -Iinc/

KEYBOARD = QWERTY
MACROS = -D $(KEYBOARD)

SRC_DIR = src
SRC = $(FILES:%=$(SRC_DIR)/%)

NAME = rt

OBJ_DIR = obj
OBJ = $(FILES:%.c=$(OBJ_DIR)/%.o)

ifdef DEB
FLAGS += -fsanitize=address -g3
CFLAGS += -fsanitize=address -g3
endif

INC = inc/rt.h inc/types.h inc/libgxns.h inc/common.h
LIB = libgxns/libgxns.a
CC = gcc
RM = @rm -fv
TEST_FILE = test.out
.PHONY: all, test, clean, fclean, re, force

all: $(NAME)

force:
	@true

libgxns/libgxns.a: force
	make -C libgxns/

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c $(INC)
	@mkdir $(OBJ_DIR) &> /dev/null || true
	$(CC) $(FLAGS) -o $@ -c $< $(MACROS) 

$(NAME): $(LIB) $(OBJ) Makefile $(INC)
	$(CC) $(CFLAGS) -o $@ $(OBJ)

soft_clean:
	make -C libgxns/ soft_clean
	@echo "Cleaning target:"
	$(RM) $(NAME)
	@echo "Cleaning objects:"
	$(RM) $(OBJ)

clean:
	@echo "Cleaning objects:"
	$(MAKE) -C libgxns/ fclean
	$(RM) $(OBJ)

fclean: clean
	@echo "Cleaning target:"
	$(RM) $(NAME)

re: fclean all

soft_re: soft_clean all
