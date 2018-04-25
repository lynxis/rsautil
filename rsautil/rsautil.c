/*
 * 2018 Alexander Couzens <lynxis@fe80.eu>
 * under the MIT license
 *
 * a simple rsautil to encrypt messages
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <getopt.h>

#include <mbedtls/rsa.h>
#include <mbedtls/bignum.h>
#include <mbedtls/entropy.h>
#include <mbedtls/ctr_drbg.h>



#define valid_arg(arg, msg) if (!arg) { fprintf(stderr, msg); exit(1); }

int main(int argc, char **argv) {
	char *input = NULL;
	//char input[128] = { 0 };
	size_t input_len = 128;
	unsigned char output[512] = { 0 };
	int ret;
	int ch;

	mbedtls_rsa_context ctx;
	mbedtls_entropy_context entropy;
	mbedtls_ctr_drbg_context ctr_drbg;

	/* rsa algorithm */
	mbedtls_mpi mpi_N, mpi_E;
	unsigned char const *N = NULL;
	unsigned char const *E = NULL;

	/* entropy */
	const char *pers = "rsa_encrypt";

	mbedtls_ctr_drbg_init( &ctr_drbg );
	mbedtls_entropy_init( &entropy );
	ret = mbedtls_ctr_drbg_seed( &ctr_drbg, mbedtls_entropy_func,
			&entropy, (const unsigned char *) pers,
			strlen( pers ) );
	if (ret) {
		fprintf(stderr, "No mbedtls_ctr_drbg_seed");
		exit(1);
	}

	if (argc == 1) {
		fprintf(stderr, "rsa_mbedtls -m 'input' -e 'pubkey E parameter' -n 'pubkey N parameter'");
		exit(1);
	}

	while ((ch = getopt(argc, argv, "e:m:n:")) != -1) {
		switch (ch) {
		case 'e':
			E = optarg;
			break;
		case 'm':
			//strncpy(input, optarg, 127);
			input = optarg;
			input_len = strlen(input);
			break;
		case 'n':
			N = optarg;
			break;
		}
	}

	valid_arg(E, "No E parameter given.!");
	valid_arg(N, "No N parameter given.!");
	valid_arg(input, "No input given.!");

	mbedtls_rsa_init(
			&ctx,
			MBEDTLS_RSA_PKCS_V15,
			0
			);

	mbedtls_mpi_init(&mpi_E);
	ret = mbedtls_mpi_read_string(&mpi_E,
			16,
			E);
	if (ret) {
		fprintf(stderr, "The E parameter is invalid.\n");
		exit(1);
	}

	mbedtls_mpi_init(&mpi_N);
	ret = mbedtls_mpi_read_string(&mpi_N,
			16,
			N);
	if (ret) {
		fprintf(stderr, "The N parameter is invalid.\n");
		exit(1);
	}

	ret = mbedtls_rsa_import(&ctx, &mpi_N, NULL, NULL, NULL, &mpi_E);
	if (ret) {
		fprintf(stderr, "Can not import N & E params\n");
		exit(1);
	}

	ret = mbedtls_rsa_complete(&ctx);
	if (ret) {
		fprintf(stderr, "Can not complete rsa\n");
		exit(1);
	}

	ret = mbedtls_rsa_check_pubkey(&ctx);
	if (ret) {
		fprintf(stderr, "No valid public key material found.");
		exit(1);
	}

	ret = mbedtls_rsa_pkcs1_encrypt(
			&ctx,
			mbedtls_ctr_drbg_random, /* rnd func */
			&ctr_drbg, /* *p_rng */
			MBEDTLS_RSA_PUBLIC,
			input_len,
			input,
			output);
	if (ret) {
		fprintf(stderr, "rsa encryption failed. 0x%x", ret * -1);
		exit(1);
	}

	for (int i=0; i<ctx.len; i++ ) {
		printf("%02x", output[i]);
	}
}
