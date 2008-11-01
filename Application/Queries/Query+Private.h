
@interface Query (Private)
- (void) _fireDidReceiveData:(NSData*)data ofType:(NSString*)ofType;
- (void) _fireDidFailWithError:(NSError*)error;
@end
