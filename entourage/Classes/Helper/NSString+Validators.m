

#import "NSString+Validators.h"

@implementation NSString (Validators)

/********************************************************************************/
#pragma mark - Public

- (BOOL)isValidEmail
{
    NSString *stricterFilterString = @"^[_A-Za-z0-9-+]+(\\.[_A-Za-z0-9-+]+)*@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*(\\.[A-Za-z‌​]{2,4})$";
    
    return [self matchesRegularExpression:stricterFilterString];
}

- (BOOL)isValidPhoneNumber
{
    NSString *regexCA = @"^(\\+|00)1\\s?|)\\(?([0-9]{3})\\)?[-.\\s]?([0-9]{3})[-.\\s]?([0-9]{4})$";
    NSString *regexFR = @"^((\\+|00)33\\s?|0)[67](\\s?\\d{2}){4}$";
    
#if DEBUG
    return YES;
#endif
    return [self matchesRegularExpression:regexFR] || [self matchesRegularExpression:regexCA];
}

- (BOOL)isValidCode {
    return [self matchesRegularExpression:@"^\\d*$"];
}

- (BOOL)isNotEmpty
{
	return self.length > 0;
}

- (BOOL)isNumeric
{
	NSNumber *number = [[[NSNumberFormatter alloc] init] numberFromString:self];

	return number != nil;
}

- (NSDecimalNumber *)numberFromString
{
	NSArray *array = [self componentsSeparatedByString:@"€"];
	NSString *text = array[0];
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];

	text = [text stringByReplacingOccurrencesOfString:[formatter groupingSeparator] withString:@""];
	NSDecimal decimal = [[formatter numberFromString:text] decimalValue];
	NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithDecimal:decimal];
	return amount;
}

- (NSString *) phoneNumberServerRepresentation
{
  //TODO if number if starting with a 0, it means it is a french number so replace 0 by +33
    if ([self matchesRegularExpression:@"^(0)[67](\\s?\\d{2}){4}$"])
    {
        NSRange range = NSMakeRange(0, 1);
        return [[self stringByReplacingCharactersInRange:range withString:@"+33"] stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
  //TODO: if number is not starting by a + we add one + so we assume it is a international number (maybe use NSTextCheckingTypePhoneNumber here)
    return self;
}

/********************************************************************************/
#pragma mark - Private

- (BOOL)matchesRegularExpression:(NSString *)regexString
{
	NSError *error = NULL;

	NSRegularExpression *regex =
		[NSRegularExpression regularExpressionWithPattern:regexString
												  options:NSRegularExpressionCaseInsensitive
													error:&error];

	NSUInteger numberOfMatches =
		[regex numberOfMatchesInString:self
							   options:0
								 range:NSMakeRange(0, [self length])];

	return numberOfMatches ? YES : NO;
}

@end
