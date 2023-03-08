module Hasql.Transaction.Private.Transaction where

import qualified Hasql.Session as B
import qualified Hasql.Statement as A
import Hasql.Transaction.Config
import Hasql.Transaction.Private.Prelude
import qualified Hasql.Transaction.Private.Sessions as D
import qualified Hasql.Transaction.Private.Statements as C

-- |
-- A composable abstraction over the retryable transactions.
--
-- Executes multiple queries under the specified mode and isolation level,
-- while automatically retrying the transaction in case of conflicts.
-- Thus this abstraction closely reproduces the behaviour of 'STM'.
newtype Transaction a
  = Transaction (StateT Bool B.Session a)
  deriving (Functor, Applicative, Monad)

instance Semigroup a => Semigroup (Transaction a) where
  (<>) = liftA2 (<>)

instance Monoid a => Monoid (Transaction a) where
  mempty = pure mempty
  mappend = liftA2 mappend

-- |
-- Execute the transaction using the provided isolation level and mode.
{-# INLINE run #-}
run :: Transaction a -> IsolationLevel -> Mode -> Bool -> B.Session a
run (Transaction session) isolation mode preparable =
  D.inRetryingTransaction isolation mode (runStateT session True) preparable

-- |
-- Possibly a multi-statement query,
-- which however cannot be parameterized or prepared,
-- nor can any results of it be collected.
{-# INLINE sql #-}
sql :: ByteString -> Transaction ()
sql =
  Transaction . lift . B.sql

-- |
-- Parameters and a specification of the parametric query to apply them to.
{-# INLINE statement #-}
statement :: a -> A.Statement a b -> Transaction b
statement params statement =
  Transaction . lift $ B.statement params statement

-- |
-- Cause transaction to eventually roll back.
{-# INLINE condemn #-}
condemn :: Transaction ()
condemn =
  Transaction $ put False

inTransaction :: B.Session a -> Transaction a
inTransaction = Transaction . lift
