class Env < Hash
    def initialize(keys=[],vals=[],outer=nil)
        @outer=outer
        #zip返回list,每个元素为一个pair，所以需要手动转换，和python不太一样
        keys.zip(vals).each{|p| store(*p)}
        #dup.update(keys.zip(vals))
    end
    def [](name) super(name)||@outer[name] end
    def set(name,val) key?(name) ? store(name,val): @outer.set(name,val) end
end

def add_globals(env)
    #添加操作符和运算符
    ops=[:+,:-,:*,:/, :>, :<, :>=, :<=, :==]
    ops.each{|op| 
        env[op]=lambda{|a,b| a.method(op).call(b)}
    }
    Math.methods(false).each{|k| env[k]=Math.method(k)}
    env.update({:length => lambda{|x| x.length}, :cons => lambda{|x,y| [x]+y},:car => lambda{|x| x[0]},:cdr => lambda{|x| x[1..-1]}, :append => lambda{|x,y| x+y},
  :list => lambda{|*xs| xs}, :list? => lambda{|x| x.is_a? Array}, :null? => lambda{|x| x==nil},
  :symbol? => lambda{|x| x.is_a? Symbol}, :not => lambda{|x| !x}, :display => lambda{|x| p x}})

end

def eval(x,env)
    return env[x] if x.is_a? Symbol     #表示是个变量
    return x if !x.is_a? Array           #是个数组，就是lisp中的list
    case x[0]
    when :quote         #(quote exp)
        x[1..-1]
    when :if            #(if test conseq alt) 
        _,test,conseq,alt=x
        eval(eval(test,env) ? conseq : alt,env)     #获取test的结果
    when :set!          #(set! var exp) set表示了变量已经存在的情况
        _,var,exp=x
        env.set(var,eval(exp,env))
    when :define        #(define var exp)
        _,var,exp=x
        env[var]=eval(exp,env)
    when :lambda        #(lambda (var*) exp)
        _,vars,exp=x
        #创建一个过程
        Proc.new{|*args| eval(exp,Env.new(vars,args,env))}
    when :begin         #(begin exp*)
        val=nil
        x[1..-1].each{|exp|
            val=eval(exp,env)
        }
        return val
    else                #(proc exp*)
        exps=x.map{|exp| eval(exp,env)}
        exps[0].call(*exps[1..-1])
        
    end
end

def atom(s)
    #还没看明白
    return "[" if s=='('  
    return "]" if s==')'  
    return s if s =~ /^-?\d+$/ || s =~ /^-?\d*\.\d+$/    #数值转换
    ':'+s   #当为字符串的时候直接输出
    
end

#词法分析
def parse(s)
    toks=s.gsub('(',' ( ').gsub(')',' ) ').split
    Kernel.eval(toks.map{|s| atom(s)}.join(' ').gsub(' ]',']').gsub('[ ','[').gsub(/([^\[]) /,'\1, '))
    
end
src =<<CODE  
(begin  
 (define fact (lambda (n)   
  (if (<= n 1) 1 (* n (fact (- n 1))))))  
   
 (fact 5)  
)  
CODE
keys = [1, 2, 3]
vals = ["a", "b", "c"]
env=Env.new
add_globals(env)
#p env
p (eval(parse("(log 2)"),env))
#keys=Math.methods(false)
#p (keys.zip(keys.map{|k| Math.method(k)}))
#p (eval(parse(src),env))
