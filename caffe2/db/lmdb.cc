#include <sys/stat.h>

#include "caffe2/core/db.h"
#include "caffe2/core/logging.h"
#include "lmdb.h"  // NOLINT

namespace caffe2 {
namespace db {

constexpr size_t LMDB_MAP_SIZE = 1099511627776;  // 1 TB

inline void MDB_CHECK(int mdb_status) {
  CAFFE_CHECK_EQ(mdb_status, MDB_SUCCESS) << mdb_strerror(mdb_status);
}

class LMDBCursor : public Cursor {
 public:
  explicit LMDBCursor(MDB_env* mdb_env)
      : mdb_env_(mdb_env), valid_(false) {
    MDB_CHECK(mdb_txn_begin(mdb_env_, NULL, MDB_RDONLY, &mdb_txn_));
    MDB_CHECK(mdb_dbi_open(mdb_txn_, NULL, 0, &mdb_dbi_));
    MDB_CHECK(mdb_cursor_open(mdb_txn_, mdb_dbi_, &mdb_cursor_));
    SeekToFirst();
  }
  virtual ~LMDBCursor() {
    mdb_cursor_close(mdb_cursor_);
    mdb_dbi_close(mdb_env_, mdb_dbi_);
    mdb_txn_abort(mdb_txn_);
  }
  void SeekToFirst() override { Seek(MDB_FIRST); }
  void Next() override { Seek(MDB_NEXT); }
  string key() override {
    return string(static_cast<const char*>(mdb_key_.mv_data), mdb_key_.mv_size);
  }
  string value() override {
    return string(static_cast<const char*>(mdb_value_.mv_data),
        mdb_value_.mv_size);
  }
  bool Valid() override { return valid_; }

 private:
  void Seek(MDB_cursor_op op) {
    int mdb_status = mdb_cursor_get(mdb_cursor_, &mdb_key_, &mdb_value_, op);
    if (mdb_status == MDB_NOTFOUND) {
      valid_ = false;
    } else {
      MDB_CHECK(mdb_status);
      valid_ = true;
    }
  }

  MDB_env* mdb_env_;
  MDB_txn* mdb_txn_;
  MDB_dbi mdb_dbi_;
  MDB_cursor* mdb_cursor_;
  MDB_val mdb_key_, mdb_value_;
  bool valid_;
};

class LMDBTransaction final : public Transaction {
 public:
  explicit LMDBTransaction(MDB_env* mdb_env)
      : mdb_env_(mdb_env) {
    MDB_CHECK(mdb_txn_begin(mdb_env_, NULL, 0, &mdb_txn_));
    MDB_CHECK(mdb_dbi_open(mdb_txn_, NULL, 0, &mdb_dbi_));
  }
  ~LMDBTransaction() {
    MDB_CHECK(mdb_txn_commit(mdb_txn_));
    mdb_dbi_close(mdb_env_, mdb_dbi_);
  }
  void Put(const string& key, const string& value) override;
  void Commit() override {
    MDB_CHECK(mdb_txn_commit(mdb_txn_));
    mdb_dbi_close(mdb_env_, mdb_dbi_);
    // Begin a new transaction.
    MDB_CHECK(mdb_txn_begin(mdb_env_, NULL, 0, &mdb_txn_));
    MDB_CHECK(mdb_dbi_open(mdb_txn_, NULL, 0, &mdb_dbi_));
  }

 private:
  MDB_env* mdb_env_;
  MDB_dbi mdb_dbi_;
  MDB_txn* mdb_txn_;

  DISABLE_COPY_AND_ASSIGN(LMDBTransaction);
};

class LMDB : public DB {
 public:
  LMDB(const string& source, Mode mode);
  virtual ~LMDB() { Close(); }
  void Close() override {
    if (mdb_env_ != NULL) {
      mdb_env_close(mdb_env_);
      mdb_env_ = NULL;
    }
  }
  Cursor* NewCursor() override { return new LMDBCursor(mdb_env_); }
  Transaction* NewTransaction() override {
    return new LMDBTransaction(mdb_env_);
  }

 private:
  MDB_env* mdb_env_;
};

LMDB::LMDB(const string& source, Mode mode) : DB(source, mode) {
  MDB_CHECK(mdb_env_create(&mdb_env_));
  MDB_CHECK(mdb_env_set_mapsize(mdb_env_, LMDB_MAP_SIZE));
  if (mode == NEW) {
    CAFFE_CHECK_EQ(mkdir(source.c_str(), 0744), 0) << "mkdir " << source << "failed";
  }
  int flags = 0;
  if (mode == READ) {
    flags = MDB_RDONLY | MDB_NOTLS;
  }
  MDB_CHECK(mdb_env_open(mdb_env_, source.c_str(), flags, 0664));
  CAFFE_LOG_INFO << "Opened lmdb " << source;
}

void LMDBTransaction::Put(const string& key, const string& value) {
  MDB_val mdb_key, mdb_value;
  mdb_key.mv_data = const_cast<char*>(key.data());
  mdb_key.mv_size = key.size();
  mdb_value.mv_data = const_cast<char*>(value.data());
  mdb_value.mv_size = value.size();
  MDB_CHECK(mdb_put(mdb_txn_, mdb_dbi_, &mdb_key, &mdb_value, 0));
}

REGISTER_CAFFE2_DB(LMDB, LMDB);
REGISTER_CAFFE2_DB(lmdb, LMDB);

}  // namespace db
}  // namespace caffe2