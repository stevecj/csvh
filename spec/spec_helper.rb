SPEC_DIR = File.expand_path( File.dirname(__FILE__) )
TEST_DATA_DIR = File.join(SPEC_DIR, 'test_data')
PROJECT_ROOT = File.dirname(SPEC_DIR)
PROJECT_LIB_DIR = File.join(PROJECT_ROOT, 'lib')

$LOAD_PATH.unshift PROJECT_LIB_DIR
require 'csvh'
