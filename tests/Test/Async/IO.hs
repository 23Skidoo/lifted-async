{-# LANGUAGE TemplateHaskell #-}
module Test.Async.IO
  ( ioTestGroup
  , ioTestGroupExtra
  ) where
import Control.Monad (when)
import Data.Maybe (isJust, isNothing)
import Prelude hiding (catch)

import Control.Concurrent.Lifted
import Control.Exception.Lifted

import Test.Framework

import Test.Async.Common

ioTestGroup :: Test
ioTestGroup = $(testGroupGenerator)

ioTestGroupExtra :: Test
ioTestGroupExtra =
  testGroup "async cancel rep" $
    replicate 1000 $ testCase "async cancel" async_cancel

case_async_waitCatch :: Assertion
case_async_waitCatch = do
  a <- async (return value)
  r <- waitCatch a
  case r of
    Left _  -> assertFailure ""
    Right e -> e @?= value

case_async_wait :: Assertion
case_async_wait = do
  a <- async (return value)
  r <- wait a
  assertEqual "async_wait" r value

case_async_exwaitCatch :: Assertion
case_async_exwaitCatch = do
  a <- async (throwIO TestException)
  r <- waitCatch a
  case r of
    Left e  -> fromException e @?= Just TestException
    Right _ -> assertFailure ""

case_async_exwait :: Assertion
case_async_exwait = do
  a <- async (throwIO TestException)
  (wait a >> assertFailure "") `catch` \e -> e @?= TestException

case_withAsync_waitCatch :: Assertion
case_withAsync_waitCatch = do
  withAsync (return value) $ \a -> do
    r <- waitCatch a
    case r of
      Left _  -> assertFailure ""
      Right e -> e @?= value

case_withAsync_wait2 :: Assertion
case_withAsync_wait2 = do
  a <- withAsync (threadDelay 1000000) $ return
  r <- waitCatch a
  case r of
    Left e  -> fromException e @?= Just ThreadKilled
    Right _ -> assertFailure ""

async_cancel :: Assertion
async_cancel = do
  a <- async (return value)
  cancelWith a TestException
  r <- waitCatch a
  case r of
    Left e -> fromException e @?= Just TestException
    Right r -> r @?= value

case_async_poll :: Assertion
case_async_poll = do
  a <- async (threadDelay 1000000)
  r <- poll a
  when (isJust r) $ assertFailure ""
  r <- poll a   -- poll twice, just to check we don't deadlock
  when (isJust r) $ assertFailure ""

case_async_poll2 :: Assertion
case_async_poll2 = do
  a <- async (return value)
  wait a
  r <- poll a
  when (isNothing r) $ assertFailure ""
  r <- poll a   -- poll twice, just to check we don't deadlock
  when (isNothing r) $ assertFailure ""
