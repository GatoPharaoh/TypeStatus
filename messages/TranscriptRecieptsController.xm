#import "HBTSSwitchTableViewCell.h"
#import <ChatKit/CKConversation.h>
#import <ChatKit/CKTranscriptRecipientsController.h>
#import <ChatKit/CKTranscriptRecipientsHeaderFooterView.h>
#import <UIKit/UITableView+Private.h>

#pragma mark - Constants

static NSInteger const kHBTSNumberOfExtraSections = 3;

#pragma mark - Variables

NSBundle *bundle = [[NSBundle bundleWithPath:@"/Library/PreferenceBundles/TypeStatus.bundle"] retain];

#pragma mark - View controller hook

@interface CKTranscriptRecipientsController ()

- (HBTSSwitchTableViewCell *)_typeStatus_switchCellForIndexPath:(NSIndexPath *)indexPath;
- (void)_typeStatus_configureDisableTypingCell:(HBTSSwitchTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)_typeStatus_configureDisableReadReceiptsCell:(HBTSSwitchTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@property NSInteger _typeStatus_sectionStartIndex;

@end

%hook CKTranscriptRecipientsController

%property (nonatomic, retain) NSInteger _typeStatus_sectionStartIndex;

- (void)loadView {
	%orig;
	[self.tableView registerClass:HBTSSwitchTableViewCell.class forCellReuseIdentifier:[HBTSSwitchTableViewCell identifier]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NSInteger sections = %orig;

	if (self.conversation._chatSupportsTypingIndicators && !self.conversation.isGroupConversation) {
		self._typeStatus_sectionStartIndex = sections;
		sections += kHBTSNumberOfExtraSections;
	}

	return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger sectionStartIndex = self._typeStatus_sectionStartIndex;

	if (sectionStartIndex == 0 || section < sectionStartIndex || section > sectionStartIndex + kHBTSNumberOfExtraSections) {
		return %orig;
	}

	if (section == sectionStartIndex + 2) {
		return 0;
	} else {
		return 1;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger sectionStartIndex = self._typeStatus_sectionStartIndex;

	if (sectionStartIndex == 0 || indexPath.section < sectionStartIndex || indexPath.section > sectionStartIndex + kHBTSNumberOfExtraSections) {		return %orig;
	}

	HBTSSwitchTableViewCell *cell = [self _typeStatus_switchCellForIndexPath:indexPath];

	if (indexPath.section == sectionStartIndex) {
		[self _typeStatus_configureDisableTypingCell:cell atIndexPath:indexPath];
	} else if (indexPath.section == sectionStartIndex + 1) {
		[self _typeStatus_configureDisableReadReceiptsCell:cell atIndexPath:indexPath];
	}

	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger sectionStartIndex = self._typeStatus_sectionStartIndex;

	if (sectionStartIndex == 0 || indexPath.section < sectionStartIndex || indexPath.section > sectionStartIndex + kHBTSNumberOfExtraSections) {
		return %orig;
	}

	return 44.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSInteger sectionStartIndex = self._typeStatus_sectionStartIndex + 1;

	if (sectionStartIndex == 0 || section < sectionStartIndex || section > sectionStartIndex + kHBTSNumberOfExtraSections) {
		if (section == sectionStartIndex - 1) {
			CKTranscriptRecipientsHeaderFooterView *view = (CKTranscriptRecipientsHeaderFooterView *)%orig;
			view.bottomSeparator.hidden = NO;
		}

		return %orig;
	}

	CKTranscriptRecipientsHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[CKTranscriptRecipientsHeaderFooterView identifier]];

	if (!view) {
		view = [[[CKTranscriptRecipientsHeaderFooterView alloc] initWithReuseIdentifier:[CKTranscriptRecipientsHeaderFooterView identifier]] autorelease];
	}

	view.margin = tableView._marginWidth;

	if (section == sectionStartIndex) {
		view.preceedingSectionFooterLabel.text = [bundle localizedStringForKey:@"DISABLE_TYPING_NOTIFICATIONS_EXPLANATION" value:@"" table:@"Messages"];
		view.bottomSeparator.hidden = NO;
	} else if (section == sectionStartIndex + 1) {
		view.preceedingSectionFooterLabel.text = [bundle localizedStringForKey:@"DISABLE_READ_RECEIPTS_EXPLANATION" value:@"" table:@"Messages"];
		view.bottomSeparator.hidden = YES;
	}

	return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	NSInteger sectionStartIndex = self._typeStatus_sectionStartIndex + 1;

	if (sectionStartIndex == 0 || section < sectionStartIndex || section > sectionStartIndex + kHBTSNumberOfExtraSections) {
		return %orig;
	}

	CKTranscriptRecipientsHeaderFooterView *view = (CKTranscriptRecipientsHeaderFooterView *)[self tableView:tableView viewForHeaderInSection:section];
	UILabel *label = view.preceedingSectionFooterLabel;

	return floorf([label sizeThatFits:CGSizeMake(tableView.bounds.size.width - view.margin * 2, CGFLOAT_MAX)].height) + 36;
}

%new - (HBTSSwitchTableViewCell *)_typeStatus_switchCellForIndexPath:(NSIndexPath *)indexPath {
	HBTSSwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[HBTSSwitchTableViewCell identifier] forIndexPath:indexPath];

	if (!cell) {
		cell = [[[HBTSSwitchTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[HBTSSwitchTableViewCell identifier]] autorelease];
		[cell.control addTarget:self action:@selector(_typeStatus_switchValueChanged:) forControlEvents:UIControlEventValueChanged];
	}

	return cell;
}

%new - (void)_typeStatus_configureDisableTypingCell:(HBTSSwitchTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	cell.control.tag = 0;
	cell.textLabel.text = [bundle localizedStringForKey:@"SEND_TYPING_NOTIFICATIONS" value:nil table:@"Messages"];
}

%new - (void)_typeStatus_configureDisableReadReceiptsCell:(HBTSSwitchTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	cell.control.tag = 1;
	cell.textLabel.text = [bundle localizedStringForKey:@"SEND_READ_RECEIPTS" value:nil table:@"Messages"];
}

%new - (void)_typeStatus_switchValueChanged:(UISwitch *)sender {
	NSString *key = nil;

	switch (sender.tag) {
		case 0:
			key = @"Typing";
			break;

		case 1:
			key = @"Read";
			break;
	}
}

%end
