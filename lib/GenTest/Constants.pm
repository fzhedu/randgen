# Copyright (C) 2008-2009 Sun Microsystems, Inc. All rights reserved.
# Use is subject to license terms.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301
# USA

package GenTest::Constants;

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(
	STATUS_OK
	STATUS_UNKNOWN_ERROR
	STATUS_ANY_ERROR

	STATUS_EOF
	STATUS_ENVIRONMENT_FAILURE

	STATUS_CUSTOM_OUTCOME

	STATUS_WONT_HANDLE
	STATUS_SKIP

	STATUS_SYNTAX_ERROR
	STATUS_SEMANTIC_ERROR
	STATUS_TRANSACTION_ERROR

	STATUS_TEST_FAILURE

	STATUS_ERROR_MISMATCH_SELECT
	STATUS_LENGTH_MISMATCH_SELECT
	STATUS_CONTENT_MISMATCH_SELECT
	STATUS_SELECT_REDUCTION

	STATUS_ERROR_MISMATCH
	STATUS_LENGTH_MISMATCH
	STATUS_CONTENT_MISMATCH

	STATUS_CRITICAL_FAILURE
	STATUS_SERVER_CRASHED
	STATUS_SERVER_KILLED
	STATUS_REPLICATION_FAILURE
	STATUS_BACKUP_FAILURE
	STATUS_RECOVERY_FAILURE
	STATUS_DATABASE_CORRUPTION
	STATUS_SERVER_DEADLOCKED

	ORACLE_ISSUE_STILL_REPEATABLE
	ORACLE_ISSUE_NO_LONGER_REPEATABLE
	ORACLE_ISSUE_STATUS_UNKNOWN

	DB_UNKNOWN
    DB_DUMMY
	DB_MYSQL
	DB_POSTGRES
	DB_JAVADB
	DB_DRIZZLE

    DEFAULT_MTR_BUILD_THREAD
);

use constant STATUS_OK				=> 0; ## Suitable for exit code
use constant STATUS_UNKNOWN_ERROR		=> 2;

use constant STATUS_ANY_ERROR			=> 3;	# Used in util/simplify* to not differentiate based on error code

use constant STATUS_EOF				=> 4;	# A module requested that the test is terminated without failure

use constant STATUS_WONT_HANDLE			=> 5;	# A module, e.g. a Validator refuses to handle certain query
use constant STATUS_SKIP			=> 6;	# A Filter specifies that the query should not be processed further

use constant STATUS_SYNTAX_ERROR		=> 21;
use constant STATUS_SEMANTIC_ERROR		=> 22;	# Errors caused by the randomness of the test, e.g. dropping a non-existing table
use constant STATUS_TRANSACTION_ERROR		=> 23;	# Lock wait timeouts, deadlocks, duplicate keys, etc.

use constant STATUS_TEST_FAILURE		=> 24;	# Boundary between genuine errors and false positives due to randomness

use constant STATUS_SELECT_REDUCTION		=> 5;	# A coefficient to substract from error codes in order to make them non-fatal

use constant STATUS_ERROR_MISMATCH_SELECT	=> 26;	# A SELECT query caused those erros, however the test can continue
use constant STATUS_LENGTH_MISMATCH_SELECT	=> 27;	# since the database has not been modified
use constant STATUS_CONTENT_MISMATCH_SELECT		=> 28;	# 

use constant STATUS_ERROR_MISMATCH		=> 31;	# A DML statement caused those errors, and the test can not continue
use constant STATUS_LENGTH_MISMATCH		=> 32;	# because the databases are in an unknown inconsistent state
use constant STATUS_CONTENT_MISMATCH		=> 33;	#

# Higher-priority errors

use constant STATUS_CRITICAL_FAILURE		=> 30;	# Boundary between critical and non-critical errors

use constant STATUS_ENVIRONMENT_FAILURE		=> 34;	# A failure in the environment or the grammar file

use constant STATUS_CUSTOM_OUTCOME		=> 35;	# Used for things such as signaling an EXPLAIN hit from the ExplainMatch Validator

use constant STATUS_SERVER_CRASHED		=> 101;

use constant STATUS_SERVER_KILLED		=> 102;	# Willfull killing of the server, will not be reported as a crash

use constant STATUS_REPLICATION_FAILURE		=> 103;
use constant STATUS_RECOVERY_FAILURE		=> 104;
use constant STATUS_DATABASE_CORRUPTION		=> 105;
use constant STATUS_SERVER_DEADLOCKED		=> 106;
use constant STATUS_BACKUP_FAILURE		=> 107;

use constant ORACLE_ISSUE_STILL_REPEATABLE	=> 1;
use constant ORACLE_ISSUE_NO_LONGER_REPEATABLE	=> 0;
use constant ORACLE_ISSUE_STATUS_UNKNOWN	=> 2;

use constant DB_UNKNOWN		=> 0;
use constant DB_DUMMY        => 1;
use constant DB_MYSQL		=> 2;
use constant DB_POSTGRES	=> 3;
use constant DB_JAVADB		=> 4;
use constant DB_DRIZZLE		=> 5;

use constant DEFAULT_MTR_BUILD_THREAD => 930; ## Legacy...

1;
