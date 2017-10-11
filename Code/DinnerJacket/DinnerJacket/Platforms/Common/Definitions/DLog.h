//
//  DLog.h
//  DinnerJacket
//
//  Created by Nicolás Miari on 2016/09/10.
//  Copyright © 2016 Nicolás Miari. All rights reserved.
//

#ifndef DLog_h
#define DLog_h

#ifdef DEBUG
#define DLog(fmt, ...) NSLog((fmt), ##__VA_ARGS__);
#else
#define DLog(...)
#endif

#endif /* DLog_h */
