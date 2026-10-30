/* Copyright (c) 2026 Thales.
 *
 * Copyright and related rights are licensed under the Apache
 * License, Version 2.0 (the "License"); you may not use this file except in
 * compliance with the License.  You may obtain a copy of the License at
 * https://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable law
 * or agreed to in writing, software, hardware and materials distributed under
 * this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * Author:         Julien Mallet -  J-Mallet on github.com
 *
 * script Name:    QOA encoder application
 *
 * ===========================================================================
 * Revisions  :
 * Date        Version  Author		Description
 * 2026-10-22  0.1      J.Mallet 	Created
 * ===========================================================================
 */

#define QOA_IMPLEMENTATION
#define QOA_NO_STDIO
#include "qoa.h"

#include <stdio.h>
#include <string.h>
#include <stdint.h>

#include "corpus.h"     /* corpus[]: single 1 s clip	  */
#include "golden.h"     /* golden[]: reference encoded stream */

#define golden_len 6504

#define read_csr(reg) ({ unsigned long __v; \
	__asm__ volatile ("csrr %0, " #reg : "=r"(__v)); __v; })


int main(void)
{
	int fail = 0;

	qoa_desc qoa = { .channels = 1, .samplerate = 16000, .samples = N };
	unsigned int len = 0;
	int bad;

	unsigned long cyc  = -read_csr(mcycle);
	unsigned long inst = -read_csr(minstret);

	uint8_t *out = qoa_encode(corpus, &qoa, &len);

	cyc  += read_csr(mcycle);
	inst += read_csr(minstret);

	bad = (!out || len != golden_len
		|| memcmp(out, golden, len) != 0);

	printf("clip: %u bytes, %lu cycles, %lu instr, encode %s\n",
		len, cyc, inst, bad ? "FAIL" : "OK");

	if (bad)
		fail = 1;

	QOA_FREE(out);

	printf(fail ? "FAIL: result values incorrect\n" : "SUCCESS: clip matches\n");
	return fail;
}
