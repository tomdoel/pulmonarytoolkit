classdef TestStack < PTKTest
    % TestStack. Tests for the PTKStack class.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    methods
        function obj = TestStack
            v1 = 'Banana';
            v2 = 'Orange';
            v3 = 'Apple';
            v4 = 'Pineapple';
            
            test_stack1 = PTKStack;
            obj.Assert(test_stack1.IsEmpty, 'Stack empty');            
            test_stack1.Push(v1);
            obj.Assert(~test_stack1.IsEmpty, 'Stack not empty');
            test_stack1.Push({v2, v3});
            obj.Assert(strcmp(v3, test_stack1.Pop), 'Expected value from stack');
            test_stack1.Push(v4);
            obj.Assert(strcmp(v4, test_stack1.Pop), 'Expected value from stack');
            obj.Assert(strcmp(v2, test_stack1.Pop), 'Expected value from stack');
            obj.Assert(~test_stack1.IsEmpty, 'Stack not empty');
            obj.Assert(strcmp(v1, test_stack1.Pop), 'Expected value from stack');
            obj.Assert(test_stack1.IsEmpty, 'Stack empty');
            
            test_stack2 = PTKStack({v1, v2});
            obj.Assert(~test_stack2.IsEmpty, 'Stack not empty');
            obj.Assert(strcmp(v2, test_stack2.Pop), 'Expected value from stack');
            test_stack2.Push({v3, v4});
            obj.Assert(strcmp(v4, test_stack2.Pop), 'Expected value from stack');
            obj.Assert(strcmp(v3, test_stack2.Pop), 'Expected value from stack');
            obj.Assert(~test_stack2.IsEmpty, 'Stack not empty');
            obj.Assert(strcmp(v1, test_stack2.Pop), 'Expected value from stack');
            obj.Assert(test_stack2.IsEmpty, 'Stack empty');
            
            test_stack3 = PTKStack({v1, v2});
            obj.Assert(strcmp({v1, v2}, test_stack3.GetAndClear), 'Expected value from stack');
            obj.Assert(test_stack3.IsEmpty, 'Stack empty');
            
            test_stack4 = PTKStack(v1);
            obj.Assert(strcmp({v1}, test_stack4.GetAndClear), 'Expected value from stack');
            obj.Assert(test_stack4.IsEmpty, 'Stack empty');

            p1 = PTKPair(v1, 10);
            p2 = PTKPair(v2, 99);
            p3 = PTKPair(v3, 101);
            test_stack4 = PTKStack(p1);
            obj.Assert(~test_stack4.IsEmpty, 'Stack not empty');
            obj.Assert(isequal({p1}, test_stack4.GetAndClear), 'Expected value from stack');
            obj.Assert(test_stack4.IsEmpty, 'Stack empty');
            test_stack4.Push([p1 p2 p3]);
            obj.Assert(isequal(p3, test_stack4.Pop), 'Expected value from stack');
            obj.Assert(isequal(p2, test_stack4.Pop), 'Expected value from stack');
            obj.Assert(isequal(p1, test_stack4.Pop), 'Expected value from stack');
            obj.Assert(test_stack4.IsEmpty, 'Stack empty');
            test_stack4.Push([p1 p2 p3]);
            obj.Assert(isequal({p1, p2, p3}, test_stack4.GetAndClear), 'Expected value from stack');

            test_stack5 = PTKStack([p3 p1 p2]);
            obj.Assert(~test_stack5.IsEmpty, 'Stack not empty');
            obj.Assert(isequal(p2, test_stack5.Pop), 'Expected value from stack');
            obj.Assert(isequal(p1, test_stack5.Pop), 'Expected value from stack');
            obj.Assert(isequal(p3, test_stack5.Pop), 'Expected value from stack');
            obj.Assert(test_stack5.IsEmpty, 'Stack empty');
            
        end
    end
end