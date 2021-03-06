
#include "debug.clh"

constant char nb_minus[16] =	".........XXX....";
constant char nb_plus[16] =		"......X..XXX..X.";
constant char nb_0[16] =		".XX.X..XX..X.XX.";
constant char nb_1[16] =		".X..XX...X..XXX.";
constant char nb_2[16] =		".XX.X..X..X.XXXX";
constant char nb_3[16] =		"XXX....X..XXXXX.";
constant char nb_4[16] =		"..X..XX.XXXX..X.";
constant char nb_5[16] =		"XXXXXX....X.XX..";
constant char nb_6[16] =		".XX....XXXXX.XX.";
constant char nb_7[16] =		"XXXX..X...X..X..";
constant char nb_8[16] =		".XXX.X.XX.X.XXX.";
constant char nb_9[16] =		".XX.XXXX...X.XX.";
constant char nb_X[16] =		"X..X.XX..XX.X..X";

int					write_nb(int nb, int x, int y)
{
	int2	px;
	int		buf_pos;

	px = (int2)(get_global_id(0), get_global_id(1));
	if (px.x >= x && px.x < x + 16 && px.y >= y && px.y < y + 16)
	{
		buf_pos = (px.x - x) / 4 + 4 * ((px.y - y) / 4);
		if (nb == -3 && nb_minus[buf_pos] == 'X')
			return (1);
		else if (nb == -1 && nb_plus[buf_pos] == 'X')
			return (1);
		else if (nb == 0 && nb_0[buf_pos] == 'X')
			return (1);
		else if (nb == 1 && nb_1[buf_pos] == 'X')
			return (1);
		else if (nb == 2 && nb_2[buf_pos] == 'X')
			return (1);
		else if (nb == 3 && nb_3[buf_pos] == 'X')
			return (1);
		else if (nb == 4 && nb_4[buf_pos] == 'X')
			return (1);
		else if (nb == 5 && nb_5[buf_pos] == 'X')
			return (1);
		else if (nb == 6 && nb_6[buf_pos] == 'X')
			return (1);
		else if (nb == 7 && nb_7[buf_pos] == 'X')
			return (1);
		else if (nb == 8 && nb_8[buf_pos] == 'X')
			return (1);
		else if (nb == 9 && nb_9[buf_pos] == 'X')
			return (1);
		else if (!((nb >= -3 && nb <= 9)) && nb_X[buf_pos] == 'X')
			return (1);
	}
	return (0);
}

int					logger(float16 data, int len)
{
	int		i;
	int		ret = 0;
	float	num;

	i = -1;
	while (++i < len)
	{
		num = data[i];
		if (isinf(num))
			ret |= write_nb(-sign(num) - 2						, 20 , 170 + i * 20);
		else if (isnan(num))
			ret |= write_nb(-4									, 20 , 170 + i * 20);
		else
		{
			ret |= write_nb(copysign(1, num) - 2				, 20 , 170 + i * 20);
			ret |= write_nb((int)fabs(num) / 100000000			, 40 , 170 + i * 20);
			ret |= write_nb(((int)fabs(num) / 10000000) % 10	, 60 , 170 + i * 20);
			ret |= write_nb(((int)fabs(num) / 1000000) % 10		, 80 , 170 + i * 20);
			ret |= write_nb(((int)fabs(num) / 100000) % 10		, 100, 170 + i * 20);
			ret |= write_nb(((int)fabs(num) / 10000) % 10		, 120, 170 + i * 20);
			ret |= write_nb(((int)fabs(num) / 1000) % 10		, 140, 170 + i * 20);
			ret |= write_nb(((int)fabs(num) / 100) % 10			, 160, 170 + i * 20);
			ret |= write_nb(((int)fabs(num) / 10) % 10			, 180, 170 + i * 20);
			ret |= write_nb((int)fabs(num) % 10					, 200, 170 + i * 20);
			ret |= write_nb(-2									, 220, 170 + i * 20);
			ret |= write_nb((int)(fabs(num) * 10) % 10			, 240, 170 + i * 20);
			ret |= write_nb((int)(fabs(num) * 100) % 10			, 260, 170 + i * 20);
			ret |= write_nb((int)(fabs(num) * 1000) % 10		, 280, 170 + i * 20);
			ret |= write_nb((int)(fabs(num) * 10000) % 10		, 300, 170 + i * 20);
			ret |= write_nb((int)(fabs(num) * 100000) % 10		, 320, 170 + i * 20);
			ret |= write_nb((int)(fabs(num) * 1000000) % 10		, 340, 170 + i * 20);
		}
	}
	return (ret);
}
