//
//  YamlParser.m
//  Yaml
//
//  Created by Kenji Nishishiro <marvel@programmershigh.org> on 10/05/08.
//  Copyright 2010 Kenji Nishishiro. All rights reserved.
//

#import "YamlParser.h"
#import <yaml.h>

@implementation YamlParser

NSArray *parseSequence(yaml_parser_t *parser);
NSDictionary *parseMapping(yaml_parser_t *parser);
NSObject *parseValue(yaml_event_t *event);

+ (NSObject *)objectFromString:(NSString *)string {
	yaml_parser_t parser;
	yaml_parser_initialize(&parser);
	
	const char *chars = [string UTF8String];
	yaml_parser_set_input_string(&parser, (const unsigned char *)chars, strlen(chars));
	
	while (YES) {
		yaml_event_t event;
		if (!yaml_parser_parse(&parser, &event)) {
			yaml_parser_delete(&parser);
			return nil;
		}
		
		switch (event.type) {
			case YAML_SCALAR_EVENT:
				;
				NSObject *value = parseValue(&event);
				yaml_event_delete(&event);
				yaml_parser_delete(&parser);
				return value;
			case YAML_SEQUENCE_START_EVENT:
				;
				NSArray *sequenceValue = parseSequence(&parser);
				yaml_event_delete(&event);
				yaml_parser_delete(&parser);
				return sequenceValue;
			case YAML_MAPPING_START_EVENT:
				;
				NSDictionary *mappingValue = parseMapping(&parser);
				yaml_event_delete(&event);
				yaml_parser_delete(&parser);
				return mappingValue;
			case YAML_STREAM_END_EVENT:
				yaml_event_delete(&event);
				yaml_parser_delete(&parser);
				return nil;
		}
		
		yaml_event_delete(&event);
	}
}

NSArray *parseSequence(yaml_parser_t *parser) {
	NSMutableArray *sequence = [NSMutableArray array];
	while (YES) {
		yaml_event_t event;
		if (!yaml_parser_parse(parser, &event)) {
			return nil;
		}
		
		switch (event.type) {
			case YAML_SCALAR_EVENT:
				;
				NSObject *value = parseValue(&event);
				[sequence addObject:value];
				break;
			case YAML_SEQUENCE_START_EVENT:
				;
				NSArray *sequenceValue = parseSequence(parser);
				if (!sequenceValue) {
					yaml_event_delete(&event);
					return nil;
				}
				[sequence addObject:sequenceValue];
				break;
			case YAML_SEQUENCE_END_EVENT:
				yaml_event_delete(&event);
				return sequence;
			case YAML_MAPPING_START_EVENT:
				;
				NSDictionary *mappingValue = parseMapping(parser);
				if (!mappingValue) {
					yaml_event_delete(&event);
					return nil;
				}
				[sequence addObject:mappingValue];
				break;
			case YAML_STREAM_END_EVENT:
				yaml_event_delete(&event);
				return nil;
		}
		
		yaml_event_delete(&event);
	}
}

NSDictionary *parseMapping(yaml_parser_t *parser) {
	NSMutableDictionary *mapping = [NSMutableDictionary dictionary];
	NSString *key = nil;
	while (YES) {
		yaml_event_t event;
		if (!yaml_parser_parse(parser, &event)) {
			return nil;
		}
		
		switch (event.type) {
			case YAML_SCALAR_EVENT:
				;
				NSObject *value = parseValue(&event);
				if (!key) {
					key = [value description];
				}
				else {
					[mapping setValue:value forKey:key];
					key = nil;
				}
				break;
			case YAML_SEQUENCE_START_EVENT:
				;
				NSArray *sequenceValue = parseSequence(parser);
				if (!sequenceValue) {
					yaml_event_delete(&event);
					return nil;
				}
				if (key) {
					[mapping setValue:sequenceValue forKey:key];
					key = nil;
				}
				break;
			case YAML_MAPPING_START_EVENT:
				;
				NSDictionary *mappingValue = parseMapping(parser);
				if (!mappingValue) {
					yaml_event_delete(&event);
					return nil;
				}
				if (key) {
					[mapping setValue:mappingValue forKey:key];
					key = nil;
				}
				break;
			case YAML_MAPPING_END_EVENT:
				yaml_event_delete(&event);
				return mapping;
			case YAML_STREAM_END_EVENT:
				yaml_event_delete(&event);
				return nil;
		}
		
		yaml_event_delete(&event);
	}
}

NSObject *parseValue(yaml_event_t *event) {
	NSString *value = [[[NSString alloc] initWithBytes:event->data.scalar.value length:event->data.scalar.length encoding:NSUTF8StringEncoding] autorelease];
	if (event->data.scalar.quoted_implicit) {
		return value;
	}
	else {
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateFormat:@"yyyy-MM-dd"];
		id result;
		if ([dateFormatter getObjectValue:&result forString:value errorDescription:nil]) {
			return result;
		}
		
		NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
		if ([numberFormatter getObjectValue:&result forString:value errorDescription:nil]) {
			return result;
		}
		
		// TODO: Add other type conversions.
		
		return value;
	}
}

@end
