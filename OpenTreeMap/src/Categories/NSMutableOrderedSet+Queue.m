// This file is part of the OpenTreeMap code.
//
// OpenTreeMap is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// OpenTreeMap is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with OpenTreeMap.  If not, see <http://www.gnu.org/licenses/>.

#import "NSMutableOrderedSet+Queue.h"

@implementation NSMutableOrderedSet (Queue)

- (void)enqueue:(id)item
{
    [self insertObject:item atIndex:0];
}

- (id)dequeue
{
    @synchronized (self) {
        id lastObject = [self lastObject];
        [self removeObjectAtIndex:([self count]-1)];
        return lastObject;
    }
}

- (void)requeue:(id)item
{
    @synchronized (self) {
        [self moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:[self indexOfObject:item]]
            toIndex:([self count]-1)];
    }
}

@end
