# Coredata and Realm.io Benchmark Tests

Here are some sample tests in order to benchmark the performance of two well known persistence frameworks: **Realm.io** VS **CoreData**.

All tests measured via `XCTestCase`'s' `measureBlock` function.

All conditions are meant to be the same. If for any reason you spot any incoherence, 
please warn me or contribute via a PR.

## Models

The model entity is basically the same on both Frameworks:

```swift
class Person: Object {
    
    var name:String
    var birthday:NSDate
    var street:String
    var country:String
    var personId:String
}
```

## Batch sizes

* 100
* 1K
* 10K
* 100K
* 1M

## Tests performed:

A few tests were created:

* `testInsertMainThread`
* `testInsertBackgroundThread`
* `testQueryAsynchronousFetch`
* `testFetchAllAsyncAndMoveToMainThread`
* `testDeleteBulk`


# TODO

- [X] Write tests
- [ ] Add the benchmarks in CSV format
- [ ] Run tests to 10M, 100M

# License

The MIT License (MIT)

You can check the full License [here](./LICENSE)