-- |
-- An API for declaration of transactions.
module Hasql.Transaction
  ( -- * Transaction monad
    Transaction,
    condemn,
    sql,
    statement,
    inTransaction,
  )
where

import Hasql.Transaction.Config
import Hasql.Transaction.Private.Transaction
