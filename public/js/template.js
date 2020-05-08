(function () {
	'use strict';

	var commonjsGlobal = typeof globalThis !== 'undefined' ? globalThis : typeof window !== 'undefined' ? window : typeof global !== 'undefined' ? global : typeof self !== 'undefined' ? self : {};

	function createCommonjsModule(fn, module) {
		return module = { exports: {} }, fn(module, module.exports), module.exports;
	}

	var check = function (it) {
	  return it && it.Math == Math && it;
	};

	// https://github.com/zloirock/core-js/issues/86#issuecomment-115759028
	var global_1 =
	  // eslint-disable-next-line no-undef
	  check(typeof globalThis == 'object' && globalThis) ||
	  check(typeof window == 'object' && window) ||
	  check(typeof self == 'object' && self) ||
	  check(typeof commonjsGlobal == 'object' && commonjsGlobal) ||
	  // eslint-disable-next-line no-new-func
	  Function('return this')();

	var fails = function (exec) {
	  try {
	    return !!exec();
	  } catch (error) {
	    return true;
	  }
	};

	// Thank's IE8 for his funny defineProperty
	var descriptors = !fails(function () {
	  return Object.defineProperty({}, 1, { get: function () { return 7; } })[1] != 7;
	});

	var nativePropertyIsEnumerable = {}.propertyIsEnumerable;
	var getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;

	// Nashorn ~ JDK8 bug
	var NASHORN_BUG = getOwnPropertyDescriptor && !nativePropertyIsEnumerable.call({ 1: 2 }, 1);

	// `Object.prototype.propertyIsEnumerable` method implementation
	// https://tc39.github.io/ecma262/#sec-object.prototype.propertyisenumerable
	var f = NASHORN_BUG ? function propertyIsEnumerable(V) {
	  var descriptor = getOwnPropertyDescriptor(this, V);
	  return !!descriptor && descriptor.enumerable;
	} : nativePropertyIsEnumerable;

	var objectPropertyIsEnumerable = {
		f: f
	};

	var createPropertyDescriptor = function (bitmap, value) {
	  return {
	    enumerable: !(bitmap & 1),
	    configurable: !(bitmap & 2),
	    writable: !(bitmap & 4),
	    value: value
	  };
	};

	var toString = {}.toString;

	var classofRaw = function (it) {
	  return toString.call(it).slice(8, -1);
	};

	var split = ''.split;

	// fallback for non-array-like ES3 and non-enumerable old V8 strings
	var indexedObject = fails(function () {
	  // throws an error in rhino, see https://github.com/mozilla/rhino/issues/346
	  // eslint-disable-next-line no-prototype-builtins
	  return !Object('z').propertyIsEnumerable(0);
	}) ? function (it) {
	  return classofRaw(it) == 'String' ? split.call(it, '') : Object(it);
	} : Object;

	// `RequireObjectCoercible` abstract operation
	// https://tc39.github.io/ecma262/#sec-requireobjectcoercible
	var requireObjectCoercible = function (it) {
	  if (it == undefined) throw TypeError("Can't call method on " + it);
	  return it;
	};

	// toObject with fallback for non-array-like ES3 strings



	var toIndexedObject = function (it) {
	  return indexedObject(requireObjectCoercible(it));
	};

	var isObject = function (it) {
	  return typeof it === 'object' ? it !== null : typeof it === 'function';
	};

	// `ToPrimitive` abstract operation
	// https://tc39.github.io/ecma262/#sec-toprimitive
	// instead of the ES6 spec version, we didn't implement @@toPrimitive case
	// and the second argument - flag - preferred type is a string
	var toPrimitive = function (input, PREFERRED_STRING) {
	  if (!isObject(input)) return input;
	  var fn, val;
	  if (PREFERRED_STRING && typeof (fn = input.toString) == 'function' && !isObject(val = fn.call(input))) return val;
	  if (typeof (fn = input.valueOf) == 'function' && !isObject(val = fn.call(input))) return val;
	  if (!PREFERRED_STRING && typeof (fn = input.toString) == 'function' && !isObject(val = fn.call(input))) return val;
	  throw TypeError("Can't convert object to primitive value");
	};

	var hasOwnProperty = {}.hasOwnProperty;

	var has = function (it, key) {
	  return hasOwnProperty.call(it, key);
	};

	var document$1 = global_1.document;
	// typeof document.createElement is 'object' in old IE
	var EXISTS = isObject(document$1) && isObject(document$1.createElement);

	var documentCreateElement = function (it) {
	  return EXISTS ? document$1.createElement(it) : {};
	};

	// Thank's IE8 for his funny defineProperty
	var ie8DomDefine = !descriptors && !fails(function () {
	  return Object.defineProperty(documentCreateElement('div'), 'a', {
	    get: function () { return 7; }
	  }).a != 7;
	});

	var nativeGetOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;

	// `Object.getOwnPropertyDescriptor` method
	// https://tc39.github.io/ecma262/#sec-object.getownpropertydescriptor
	var f$1 = descriptors ? nativeGetOwnPropertyDescriptor : function getOwnPropertyDescriptor(O, P) {
	  O = toIndexedObject(O);
	  P = toPrimitive(P, true);
	  if (ie8DomDefine) try {
	    return nativeGetOwnPropertyDescriptor(O, P);
	  } catch (error) { /* empty */ }
	  if (has(O, P)) return createPropertyDescriptor(!objectPropertyIsEnumerable.f.call(O, P), O[P]);
	};

	var objectGetOwnPropertyDescriptor = {
		f: f$1
	};

	var anObject = function (it) {
	  if (!isObject(it)) {
	    throw TypeError(String(it) + ' is not an object');
	  } return it;
	};

	var nativeDefineProperty = Object.defineProperty;

	// `Object.defineProperty` method
	// https://tc39.github.io/ecma262/#sec-object.defineproperty
	var f$2 = descriptors ? nativeDefineProperty : function defineProperty(O, P, Attributes) {
	  anObject(O);
	  P = toPrimitive(P, true);
	  anObject(Attributes);
	  if (ie8DomDefine) try {
	    return nativeDefineProperty(O, P, Attributes);
	  } catch (error) { /* empty */ }
	  if ('get' in Attributes || 'set' in Attributes) throw TypeError('Accessors not supported');
	  if ('value' in Attributes) O[P] = Attributes.value;
	  return O;
	};

	var objectDefineProperty = {
		f: f$2
	};

	var createNonEnumerableProperty = descriptors ? function (object, key, value) {
	  return objectDefineProperty.f(object, key, createPropertyDescriptor(1, value));
	} : function (object, key, value) {
	  object[key] = value;
	  return object;
	};

	var setGlobal = function (key, value) {
	  try {
	    createNonEnumerableProperty(global_1, key, value);
	  } catch (error) {
	    global_1[key] = value;
	  } return value;
	};

	var SHARED = '__core-js_shared__';
	var store = global_1[SHARED] || setGlobal(SHARED, {});

	var sharedStore = store;

	var functionToString = Function.toString;

	// this helper broken in `3.4.1-3.4.4`, so we can't use `shared` helper
	if (typeof sharedStore.inspectSource != 'function') {
	  sharedStore.inspectSource = function (it) {
	    return functionToString.call(it);
	  };
	}

	var inspectSource = sharedStore.inspectSource;

	var WeakMap = global_1.WeakMap;

	var nativeWeakMap = typeof WeakMap === 'function' && /native code/.test(inspectSource(WeakMap));

	var shared = createCommonjsModule(function (module) {
	(module.exports = function (key, value) {
	  return sharedStore[key] || (sharedStore[key] = value !== undefined ? value : {});
	})('versions', []).push({
	  version: '3.6.5',
	  mode:  'global',
	  copyright: '© 2020 Denis Pushkarev (zloirock.ru)'
	});
	});

	var id = 0;
	var postfix = Math.random();

	var uid = function (key) {
	  return 'Symbol(' + String(key === undefined ? '' : key) + ')_' + (++id + postfix).toString(36);
	};

	var keys = shared('keys');

	var sharedKey = function (key) {
	  return keys[key] || (keys[key] = uid(key));
	};

	var hiddenKeys = {};

	var WeakMap$1 = global_1.WeakMap;
	var set, get, has$1;

	var enforce = function (it) {
	  return has$1(it) ? get(it) : set(it, {});
	};

	var getterFor = function (TYPE) {
	  return function (it) {
	    var state;
	    if (!isObject(it) || (state = get(it)).type !== TYPE) {
	      throw TypeError('Incompatible receiver, ' + TYPE + ' required');
	    } return state;
	  };
	};

	if (nativeWeakMap) {
	  var store$1 = new WeakMap$1();
	  var wmget = store$1.get;
	  var wmhas = store$1.has;
	  var wmset = store$1.set;
	  set = function (it, metadata) {
	    wmset.call(store$1, it, metadata);
	    return metadata;
	  };
	  get = function (it) {
	    return wmget.call(store$1, it) || {};
	  };
	  has$1 = function (it) {
	    return wmhas.call(store$1, it);
	  };
	} else {
	  var STATE = sharedKey('state');
	  hiddenKeys[STATE] = true;
	  set = function (it, metadata) {
	    createNonEnumerableProperty(it, STATE, metadata);
	    return metadata;
	  };
	  get = function (it) {
	    return has(it, STATE) ? it[STATE] : {};
	  };
	  has$1 = function (it) {
	    return has(it, STATE);
	  };
	}

	var internalState = {
	  set: set,
	  get: get,
	  has: has$1,
	  enforce: enforce,
	  getterFor: getterFor
	};

	var redefine = createCommonjsModule(function (module) {
	var getInternalState = internalState.get;
	var enforceInternalState = internalState.enforce;
	var TEMPLATE = String(String).split('String');

	(module.exports = function (O, key, value, options) {
	  var unsafe = options ? !!options.unsafe : false;
	  var simple = options ? !!options.enumerable : false;
	  var noTargetGet = options ? !!options.noTargetGet : false;
	  if (typeof value == 'function') {
	    if (typeof key == 'string' && !has(value, 'name')) createNonEnumerableProperty(value, 'name', key);
	    enforceInternalState(value).source = TEMPLATE.join(typeof key == 'string' ? key : '');
	  }
	  if (O === global_1) {
	    if (simple) O[key] = value;
	    else setGlobal(key, value);
	    return;
	  } else if (!unsafe) {
	    delete O[key];
	  } else if (!noTargetGet && O[key]) {
	    simple = true;
	  }
	  if (simple) O[key] = value;
	  else createNonEnumerableProperty(O, key, value);
	// add fake Function#toString for correct work wrapped methods / constructors with methods like LoDash isNative
	})(Function.prototype, 'toString', function toString() {
	  return typeof this == 'function' && getInternalState(this).source || inspectSource(this);
	});
	});

	var path = global_1;

	var aFunction = function (variable) {
	  return typeof variable == 'function' ? variable : undefined;
	};

	var getBuiltIn = function (namespace, method) {
	  return arguments.length < 2 ? aFunction(path[namespace]) || aFunction(global_1[namespace])
	    : path[namespace] && path[namespace][method] || global_1[namespace] && global_1[namespace][method];
	};

	var ceil = Math.ceil;
	var floor = Math.floor;

	// `ToInteger` abstract operation
	// https://tc39.github.io/ecma262/#sec-tointeger
	var toInteger = function (argument) {
	  return isNaN(argument = +argument) ? 0 : (argument > 0 ? floor : ceil)(argument);
	};

	var min = Math.min;

	// `ToLength` abstract operation
	// https://tc39.github.io/ecma262/#sec-tolength
	var toLength = function (argument) {
	  return argument > 0 ? min(toInteger(argument), 0x1FFFFFFFFFFFFF) : 0; // 2 ** 53 - 1 == 9007199254740991
	};

	var max = Math.max;
	var min$1 = Math.min;

	// Helper for a popular repeating case of the spec:
	// Let integer be ? ToInteger(index).
	// If integer < 0, let result be max((length + integer), 0); else let result be min(integer, length).
	var toAbsoluteIndex = function (index, length) {
	  var integer = toInteger(index);
	  return integer < 0 ? max(integer + length, 0) : min$1(integer, length);
	};

	// `Array.prototype.{ indexOf, includes }` methods implementation
	var createMethod = function (IS_INCLUDES) {
	  return function ($this, el, fromIndex) {
	    var O = toIndexedObject($this);
	    var length = toLength(O.length);
	    var index = toAbsoluteIndex(fromIndex, length);
	    var value;
	    // Array#includes uses SameValueZero equality algorithm
	    // eslint-disable-next-line no-self-compare
	    if (IS_INCLUDES && el != el) while (length > index) {
	      value = O[index++];
	      // eslint-disable-next-line no-self-compare
	      if (value != value) return true;
	    // Array#indexOf ignores holes, Array#includes - not
	    } else for (;length > index; index++) {
	      if ((IS_INCLUDES || index in O) && O[index] === el) return IS_INCLUDES || index || 0;
	    } return !IS_INCLUDES && -1;
	  };
	};

	var arrayIncludes = {
	  // `Array.prototype.includes` method
	  // https://tc39.github.io/ecma262/#sec-array.prototype.includes
	  includes: createMethod(true),
	  // `Array.prototype.indexOf` method
	  // https://tc39.github.io/ecma262/#sec-array.prototype.indexof
	  indexOf: createMethod(false)
	};

	var indexOf = arrayIncludes.indexOf;


	var objectKeysInternal = function (object, names) {
	  var O = toIndexedObject(object);
	  var i = 0;
	  var result = [];
	  var key;
	  for (key in O) !has(hiddenKeys, key) && has(O, key) && result.push(key);
	  // Don't enum bug & hidden keys
	  while (names.length > i) if (has(O, key = names[i++])) {
	    ~indexOf(result, key) || result.push(key);
	  }
	  return result;
	};

	// IE8- don't enum bug keys
	var enumBugKeys = [
	  'constructor',
	  'hasOwnProperty',
	  'isPrototypeOf',
	  'propertyIsEnumerable',
	  'toLocaleString',
	  'toString',
	  'valueOf'
	];

	var hiddenKeys$1 = enumBugKeys.concat('length', 'prototype');

	// `Object.getOwnPropertyNames` method
	// https://tc39.github.io/ecma262/#sec-object.getownpropertynames
	var f$3 = Object.getOwnPropertyNames || function getOwnPropertyNames(O) {
	  return objectKeysInternal(O, hiddenKeys$1);
	};

	var objectGetOwnPropertyNames = {
		f: f$3
	};

	var f$4 = Object.getOwnPropertySymbols;

	var objectGetOwnPropertySymbols = {
		f: f$4
	};

	// all object keys, includes non-enumerable and symbols
	var ownKeys = getBuiltIn('Reflect', 'ownKeys') || function ownKeys(it) {
	  var keys = objectGetOwnPropertyNames.f(anObject(it));
	  var getOwnPropertySymbols = objectGetOwnPropertySymbols.f;
	  return getOwnPropertySymbols ? keys.concat(getOwnPropertySymbols(it)) : keys;
	};

	var copyConstructorProperties = function (target, source) {
	  var keys = ownKeys(source);
	  var defineProperty = objectDefineProperty.f;
	  var getOwnPropertyDescriptor = objectGetOwnPropertyDescriptor.f;
	  for (var i = 0; i < keys.length; i++) {
	    var key = keys[i];
	    if (!has(target, key)) defineProperty(target, key, getOwnPropertyDescriptor(source, key));
	  }
	};

	var replacement = /#|\.prototype\./;

	var isForced = function (feature, detection) {
	  var value = data[normalize(feature)];
	  return value == POLYFILL ? true
	    : value == NATIVE ? false
	    : typeof detection == 'function' ? fails(detection)
	    : !!detection;
	};

	var normalize = isForced.normalize = function (string) {
	  return String(string).replace(replacement, '.').toLowerCase();
	};

	var data = isForced.data = {};
	var NATIVE = isForced.NATIVE = 'N';
	var POLYFILL = isForced.POLYFILL = 'P';

	var isForced_1 = isForced;

	var getOwnPropertyDescriptor$1 = objectGetOwnPropertyDescriptor.f;






	/*
	  options.target      - name of the target object
	  options.global      - target is the global object
	  options.stat        - export as static methods of target
	  options.proto       - export as prototype methods of target
	  options.real        - real prototype method for the `pure` version
	  options.forced      - export even if the native feature is available
	  options.bind        - bind methods to the target, required for the `pure` version
	  options.wrap        - wrap constructors to preventing global pollution, required for the `pure` version
	  options.unsafe      - use the simple assignment of property instead of delete + defineProperty
	  options.sham        - add a flag to not completely full polyfills
	  options.enumerable  - export as enumerable property
	  options.noTargetGet - prevent calling a getter on target
	*/
	var _export = function (options, source) {
	  var TARGET = options.target;
	  var GLOBAL = options.global;
	  var STATIC = options.stat;
	  var FORCED, target, key, targetProperty, sourceProperty, descriptor;
	  if (GLOBAL) {
	    target = global_1;
	  } else if (STATIC) {
	    target = global_1[TARGET] || setGlobal(TARGET, {});
	  } else {
	    target = (global_1[TARGET] || {}).prototype;
	  }
	  if (target) for (key in source) {
	    sourceProperty = source[key];
	    if (options.noTargetGet) {
	      descriptor = getOwnPropertyDescriptor$1(target, key);
	      targetProperty = descriptor && descriptor.value;
	    } else targetProperty = target[key];
	    FORCED = isForced_1(GLOBAL ? key : TARGET + (STATIC ? '.' : '#') + key, options.forced);
	    // contained in target
	    if (!FORCED && targetProperty !== undefined) {
	      if (typeof sourceProperty === typeof targetProperty) continue;
	      copyConstructorProperties(sourceProperty, targetProperty);
	    }
	    // add a flag to not completely full polyfills
	    if (options.sham || (targetProperty && targetProperty.sham)) {
	      createNonEnumerableProperty(sourceProperty, 'sham', true);
	    }
	    // extend global
	    redefine(target, key, sourceProperty, options);
	  }
	};

	// `IsArray` abstract operation
	// https://tc39.github.io/ecma262/#sec-isarray
	var isArray = Array.isArray || function isArray(arg) {
	  return classofRaw(arg) == 'Array';
	};

	// `ToObject` abstract operation
	// https://tc39.github.io/ecma262/#sec-toobject
	var toObject = function (argument) {
	  return Object(requireObjectCoercible(argument));
	};

	var createProperty = function (object, key, value) {
	  var propertyKey = toPrimitive(key);
	  if (propertyKey in object) objectDefineProperty.f(object, propertyKey, createPropertyDescriptor(0, value));
	  else object[propertyKey] = value;
	};

	var nativeSymbol = !!Object.getOwnPropertySymbols && !fails(function () {
	  // Chrome 38 Symbol has incorrect toString conversion
	  // eslint-disable-next-line no-undef
	  return !String(Symbol());
	});

	var useSymbolAsUid = nativeSymbol
	  // eslint-disable-next-line no-undef
	  && !Symbol.sham
	  // eslint-disable-next-line no-undef
	  && typeof Symbol.iterator == 'symbol';

	var WellKnownSymbolsStore = shared('wks');
	var Symbol$1 = global_1.Symbol;
	var createWellKnownSymbol = useSymbolAsUid ? Symbol$1 : Symbol$1 && Symbol$1.withoutSetter || uid;

	var wellKnownSymbol = function (name) {
	  if (!has(WellKnownSymbolsStore, name)) {
	    if (nativeSymbol && has(Symbol$1, name)) WellKnownSymbolsStore[name] = Symbol$1[name];
	    else WellKnownSymbolsStore[name] = createWellKnownSymbol('Symbol.' + name);
	  } return WellKnownSymbolsStore[name];
	};

	var SPECIES = wellKnownSymbol('species');

	// `ArraySpeciesCreate` abstract operation
	// https://tc39.github.io/ecma262/#sec-arrayspeciescreate
	var arraySpeciesCreate = function (originalArray, length) {
	  var C;
	  if (isArray(originalArray)) {
	    C = originalArray.constructor;
	    // cross-realm fallback
	    if (typeof C == 'function' && (C === Array || isArray(C.prototype))) C = undefined;
	    else if (isObject(C)) {
	      C = C[SPECIES];
	      if (C === null) C = undefined;
	    }
	  } return new (C === undefined ? Array : C)(length === 0 ? 0 : length);
	};

	var engineUserAgent = getBuiltIn('navigator', 'userAgent') || '';

	var process = global_1.process;
	var versions = process && process.versions;
	var v8 = versions && versions.v8;
	var match, version;

	if (v8) {
	  match = v8.split('.');
	  version = match[0] + match[1];
	} else if (engineUserAgent) {
	  match = engineUserAgent.match(/Edge\/(\d+)/);
	  if (!match || match[1] >= 74) {
	    match = engineUserAgent.match(/Chrome\/(\d+)/);
	    if (match) version = match[1];
	  }
	}

	var engineV8Version = version && +version;

	var SPECIES$1 = wellKnownSymbol('species');

	var arrayMethodHasSpeciesSupport = function (METHOD_NAME) {
	  // We can't use this feature detection in V8 since it causes
	  // deoptimization and serious performance degradation
	  // https://github.com/zloirock/core-js/issues/677
	  return engineV8Version >= 51 || !fails(function () {
	    var array = [];
	    var constructor = array.constructor = {};
	    constructor[SPECIES$1] = function () {
	      return { foo: 1 };
	    };
	    return array[METHOD_NAME](Boolean).foo !== 1;
	  });
	};

	var IS_CONCAT_SPREADABLE = wellKnownSymbol('isConcatSpreadable');
	var MAX_SAFE_INTEGER = 0x1FFFFFFFFFFFFF;
	var MAXIMUM_ALLOWED_INDEX_EXCEEDED = 'Maximum allowed index exceeded';

	// We can't use this feature detection in V8 since it causes
	// deoptimization and serious performance degradation
	// https://github.com/zloirock/core-js/issues/679
	var IS_CONCAT_SPREADABLE_SUPPORT = engineV8Version >= 51 || !fails(function () {
	  var array = [];
	  array[IS_CONCAT_SPREADABLE] = false;
	  return array.concat()[0] !== array;
	});

	var SPECIES_SUPPORT = arrayMethodHasSpeciesSupport('concat');

	var isConcatSpreadable = function (O) {
	  if (!isObject(O)) return false;
	  var spreadable = O[IS_CONCAT_SPREADABLE];
	  return spreadable !== undefined ? !!spreadable : isArray(O);
	};

	var FORCED = !IS_CONCAT_SPREADABLE_SUPPORT || !SPECIES_SUPPORT;

	// `Array.prototype.concat` method
	// https://tc39.github.io/ecma262/#sec-array.prototype.concat
	// with adding support of @@isConcatSpreadable and @@species
	_export({ target: 'Array', proto: true, forced: FORCED }, {
	  concat: function concat(arg) { // eslint-disable-line no-unused-vars
	    var O = toObject(this);
	    var A = arraySpeciesCreate(O, 0);
	    var n = 0;
	    var i, k, length, len, E;
	    for (i = -1, length = arguments.length; i < length; i++) {
	      E = i === -1 ? O : arguments[i];
	      if (isConcatSpreadable(E)) {
	        len = toLength(E.length);
	        if (n + len > MAX_SAFE_INTEGER) throw TypeError(MAXIMUM_ALLOWED_INDEX_EXCEEDED);
	        for (k = 0; k < len; k++, n++) if (k in E) createProperty(A, n, E[k]);
	      } else {
	        if (n >= MAX_SAFE_INTEGER) throw TypeError(MAXIMUM_ALLOWED_INDEX_EXCEEDED);
	        createProperty(A, n++, E);
	      }
	    }
	    A.length = n;
	    return A;
	  }
	});

	var aFunction$1 = function (it) {
	  if (typeof it != 'function') {
	    throw TypeError(String(it) + ' is not a function');
	  } return it;
	};

	// optional / simple context binding
	var functionBindContext = function (fn, that, length) {
	  aFunction$1(fn);
	  if (that === undefined) return fn;
	  switch (length) {
	    case 0: return function () {
	      return fn.call(that);
	    };
	    case 1: return function (a) {
	      return fn.call(that, a);
	    };
	    case 2: return function (a, b) {
	      return fn.call(that, a, b);
	    };
	    case 3: return function (a, b, c) {
	      return fn.call(that, a, b, c);
	    };
	  }
	  return function (/* ...args */) {
	    return fn.apply(that, arguments);
	  };
	};

	var push = [].push;

	// `Array.prototype.{ forEach, map, filter, some, every, find, findIndex }` methods implementation
	var createMethod$1 = function (TYPE) {
	  var IS_MAP = TYPE == 1;
	  var IS_FILTER = TYPE == 2;
	  var IS_SOME = TYPE == 3;
	  var IS_EVERY = TYPE == 4;
	  var IS_FIND_INDEX = TYPE == 6;
	  var NO_HOLES = TYPE == 5 || IS_FIND_INDEX;
	  return function ($this, callbackfn, that, specificCreate) {
	    var O = toObject($this);
	    var self = indexedObject(O);
	    var boundFunction = functionBindContext(callbackfn, that, 3);
	    var length = toLength(self.length);
	    var index = 0;
	    var create = specificCreate || arraySpeciesCreate;
	    var target = IS_MAP ? create($this, length) : IS_FILTER ? create($this, 0) : undefined;
	    var value, result;
	    for (;length > index; index++) if (NO_HOLES || index in self) {
	      value = self[index];
	      result = boundFunction(value, index, O);
	      if (TYPE) {
	        if (IS_MAP) target[index] = result; // map
	        else if (result) switch (TYPE) {
	          case 3: return true;              // some
	          case 5: return value;             // find
	          case 6: return index;             // findIndex
	          case 2: push.call(target, value); // filter
	        } else if (IS_EVERY) return false;  // every
	      }
	    }
	    return IS_FIND_INDEX ? -1 : IS_SOME || IS_EVERY ? IS_EVERY : target;
	  };
	};

	var arrayIteration = {
	  // `Array.prototype.forEach` method
	  // https://tc39.github.io/ecma262/#sec-array.prototype.foreach
	  forEach: createMethod$1(0),
	  // `Array.prototype.map` method
	  // https://tc39.github.io/ecma262/#sec-array.prototype.map
	  map: createMethod$1(1),
	  // `Array.prototype.filter` method
	  // https://tc39.github.io/ecma262/#sec-array.prototype.filter
	  filter: createMethod$1(2),
	  // `Array.prototype.some` method
	  // https://tc39.github.io/ecma262/#sec-array.prototype.some
	  some: createMethod$1(3),
	  // `Array.prototype.every` method
	  // https://tc39.github.io/ecma262/#sec-array.prototype.every
	  every: createMethod$1(4),
	  // `Array.prototype.find` method
	  // https://tc39.github.io/ecma262/#sec-array.prototype.find
	  find: createMethod$1(5),
	  // `Array.prototype.findIndex` method
	  // https://tc39.github.io/ecma262/#sec-array.prototype.findIndex
	  findIndex: createMethod$1(6)
	};

	// `Object.keys` method
	// https://tc39.github.io/ecma262/#sec-object.keys
	var objectKeys = Object.keys || function keys(O) {
	  return objectKeysInternal(O, enumBugKeys);
	};

	// `Object.defineProperties` method
	// https://tc39.github.io/ecma262/#sec-object.defineproperties
	var objectDefineProperties = descriptors ? Object.defineProperties : function defineProperties(O, Properties) {
	  anObject(O);
	  var keys = objectKeys(Properties);
	  var length = keys.length;
	  var index = 0;
	  var key;
	  while (length > index) objectDefineProperty.f(O, key = keys[index++], Properties[key]);
	  return O;
	};

	var html = getBuiltIn('document', 'documentElement');

	var GT = '>';
	var LT = '<';
	var PROTOTYPE = 'prototype';
	var SCRIPT = 'script';
	var IE_PROTO = sharedKey('IE_PROTO');

	var EmptyConstructor = function () { /* empty */ };

	var scriptTag = function (content) {
	  return LT + SCRIPT + GT + content + LT + '/' + SCRIPT + GT;
	};

	// Create object with fake `null` prototype: use ActiveX Object with cleared prototype
	var NullProtoObjectViaActiveX = function (activeXDocument) {
	  activeXDocument.write(scriptTag(''));
	  activeXDocument.close();
	  var temp = activeXDocument.parentWindow.Object;
	  activeXDocument = null; // avoid memory leak
	  return temp;
	};

	// Create object with fake `null` prototype: use iframe Object with cleared prototype
	var NullProtoObjectViaIFrame = function () {
	  // Thrash, waste and sodomy: IE GC bug
	  var iframe = documentCreateElement('iframe');
	  var JS = 'java' + SCRIPT + ':';
	  var iframeDocument;
	  iframe.style.display = 'none';
	  html.appendChild(iframe);
	  // https://github.com/zloirock/core-js/issues/475
	  iframe.src = String(JS);
	  iframeDocument = iframe.contentWindow.document;
	  iframeDocument.open();
	  iframeDocument.write(scriptTag('document.F=Object'));
	  iframeDocument.close();
	  return iframeDocument.F;
	};

	// Check for document.domain and active x support
	// No need to use active x approach when document.domain is not set
	// see https://github.com/es-shims/es5-shim/issues/150
	// variation of https://github.com/kitcambridge/es5-shim/commit/4f738ac066346
	// avoid IE GC bug
	var activeXDocument;
	var NullProtoObject = function () {
	  try {
	    /* global ActiveXObject */
	    activeXDocument = document.domain && new ActiveXObject('htmlfile');
	  } catch (error) { /* ignore */ }
	  NullProtoObject = activeXDocument ? NullProtoObjectViaActiveX(activeXDocument) : NullProtoObjectViaIFrame();
	  var length = enumBugKeys.length;
	  while (length--) delete NullProtoObject[PROTOTYPE][enumBugKeys[length]];
	  return NullProtoObject();
	};

	hiddenKeys[IE_PROTO] = true;

	// `Object.create` method
	// https://tc39.github.io/ecma262/#sec-object.create
	var objectCreate = Object.create || function create(O, Properties) {
	  var result;
	  if (O !== null) {
	    EmptyConstructor[PROTOTYPE] = anObject(O);
	    result = new EmptyConstructor();
	    EmptyConstructor[PROTOTYPE] = null;
	    // add "__proto__" for Object.getPrototypeOf polyfill
	    result[IE_PROTO] = O;
	  } else result = NullProtoObject();
	  return Properties === undefined ? result : objectDefineProperties(result, Properties);
	};

	var UNSCOPABLES = wellKnownSymbol('unscopables');
	var ArrayPrototype = Array.prototype;

	// Array.prototype[@@unscopables]
	// https://tc39.github.io/ecma262/#sec-array.prototype-@@unscopables
	if (ArrayPrototype[UNSCOPABLES] == undefined) {
	  objectDefineProperty.f(ArrayPrototype, UNSCOPABLES, {
	    configurable: true,
	    value: objectCreate(null)
	  });
	}

	// add a key to Array.prototype[@@unscopables]
	var addToUnscopables = function (key) {
	  ArrayPrototype[UNSCOPABLES][key] = true;
	};

	var defineProperty = Object.defineProperty;
	var cache = {};

	var thrower = function (it) { throw it; };

	var arrayMethodUsesToLength = function (METHOD_NAME, options) {
	  if (has(cache, METHOD_NAME)) return cache[METHOD_NAME];
	  if (!options) options = {};
	  var method = [][METHOD_NAME];
	  var ACCESSORS = has(options, 'ACCESSORS') ? options.ACCESSORS : false;
	  var argument0 = has(options, 0) ? options[0] : thrower;
	  var argument1 = has(options, 1) ? options[1] : undefined;

	  return cache[METHOD_NAME] = !!method && !fails(function () {
	    if (ACCESSORS && !descriptors) return true;
	    var O = { length: -1 };

	    if (ACCESSORS) defineProperty(O, 1, { enumerable: true, get: thrower });
	    else O[1] = 1;

	    method.call(O, argument0, argument1);
	  });
	};

	var $find = arrayIteration.find;



	var FIND = 'find';
	var SKIPS_HOLES = true;

	var USES_TO_LENGTH = arrayMethodUsesToLength(FIND);

	// Shouldn't skip holes
	if (FIND in []) Array(1)[FIND](function () { SKIPS_HOLES = false; });

	// `Array.prototype.find` method
	// https://tc39.github.io/ecma262/#sec-array.prototype.find
	_export({ target: 'Array', proto: true, forced: SKIPS_HOLES || !USES_TO_LENGTH }, {
	  find: function find(callbackfn /* , that = undefined */) {
	    return $find(this, callbackfn, arguments.length > 1 ? arguments[1] : undefined);
	  }
	});

	// https://tc39.github.io/ecma262/#sec-array.prototype-@@unscopables
	addToUnscopables(FIND);

	var $includes = arrayIncludes.includes;



	var USES_TO_LENGTH$1 = arrayMethodUsesToLength('indexOf', { ACCESSORS: true, 1: 0 });

	// `Array.prototype.includes` method
	// https://tc39.github.io/ecma262/#sec-array.prototype.includes
	_export({ target: 'Array', proto: true, forced: !USES_TO_LENGTH$1 }, {
	  includes: function includes(el /* , fromIndex = 0 */) {
	    return $includes(this, el, arguments.length > 1 ? arguments[1] : undefined);
	  }
	});

	// https://tc39.github.io/ecma262/#sec-array.prototype-@@unscopables
	addToUnscopables('includes');

	var correctPrototypeGetter = !fails(function () {
	  function F() { /* empty */ }
	  F.prototype.constructor = null;
	  return Object.getPrototypeOf(new F()) !== F.prototype;
	});

	var IE_PROTO$1 = sharedKey('IE_PROTO');
	var ObjectPrototype = Object.prototype;

	// `Object.getPrototypeOf` method
	// https://tc39.github.io/ecma262/#sec-object.getprototypeof
	var objectGetPrototypeOf = correctPrototypeGetter ? Object.getPrototypeOf : function (O) {
	  O = toObject(O);
	  if (has(O, IE_PROTO$1)) return O[IE_PROTO$1];
	  if (typeof O.constructor == 'function' && O instanceof O.constructor) {
	    return O.constructor.prototype;
	  } return O instanceof Object ? ObjectPrototype : null;
	};

	var ITERATOR = wellKnownSymbol('iterator');
	var BUGGY_SAFARI_ITERATORS = false;

	var returnThis = function () { return this; };

	// `%IteratorPrototype%` object
	// https://tc39.github.io/ecma262/#sec-%iteratorprototype%-object
	var IteratorPrototype, PrototypeOfArrayIteratorPrototype, arrayIterator;

	if ([].keys) {
	  arrayIterator = [].keys();
	  // Safari 8 has buggy iterators w/o `next`
	  if (!('next' in arrayIterator)) BUGGY_SAFARI_ITERATORS = true;
	  else {
	    PrototypeOfArrayIteratorPrototype = objectGetPrototypeOf(objectGetPrototypeOf(arrayIterator));
	    if (PrototypeOfArrayIteratorPrototype !== Object.prototype) IteratorPrototype = PrototypeOfArrayIteratorPrototype;
	  }
	}

	if (IteratorPrototype == undefined) IteratorPrototype = {};

	// 25.1.2.1.1 %IteratorPrototype%[@@iterator]()
	if ( !has(IteratorPrototype, ITERATOR)) {
	  createNonEnumerableProperty(IteratorPrototype, ITERATOR, returnThis);
	}

	var iteratorsCore = {
	  IteratorPrototype: IteratorPrototype,
	  BUGGY_SAFARI_ITERATORS: BUGGY_SAFARI_ITERATORS
	};

	var defineProperty$1 = objectDefineProperty.f;



	var TO_STRING_TAG = wellKnownSymbol('toStringTag');

	var setToStringTag = function (it, TAG, STATIC) {
	  if (it && !has(it = STATIC ? it : it.prototype, TO_STRING_TAG)) {
	    defineProperty$1(it, TO_STRING_TAG, { configurable: true, value: TAG });
	  }
	};

	var IteratorPrototype$1 = iteratorsCore.IteratorPrototype;

	var createIteratorConstructor = function (IteratorConstructor, NAME, next) {
	  var TO_STRING_TAG = NAME + ' Iterator';
	  IteratorConstructor.prototype = objectCreate(IteratorPrototype$1, { next: createPropertyDescriptor(1, next) });
	  setToStringTag(IteratorConstructor, TO_STRING_TAG, false);
	  return IteratorConstructor;
	};

	var aPossiblePrototype = function (it) {
	  if (!isObject(it) && it !== null) {
	    throw TypeError("Can't set " + String(it) + ' as a prototype');
	  } return it;
	};

	// `Object.setPrototypeOf` method
	// https://tc39.github.io/ecma262/#sec-object.setprototypeof
	// Works with __proto__ only. Old v8 can't work with null proto objects.
	/* eslint-disable no-proto */
	var objectSetPrototypeOf = Object.setPrototypeOf || ('__proto__' in {} ? function () {
	  var CORRECT_SETTER = false;
	  var test = {};
	  var setter;
	  try {
	    setter = Object.getOwnPropertyDescriptor(Object.prototype, '__proto__').set;
	    setter.call(test, []);
	    CORRECT_SETTER = test instanceof Array;
	  } catch (error) { /* empty */ }
	  return function setPrototypeOf(O, proto) {
	    anObject(O);
	    aPossiblePrototype(proto);
	    if (CORRECT_SETTER) setter.call(O, proto);
	    else O.__proto__ = proto;
	    return O;
	  };
	}() : undefined);

	var IteratorPrototype$2 = iteratorsCore.IteratorPrototype;
	var BUGGY_SAFARI_ITERATORS$1 = iteratorsCore.BUGGY_SAFARI_ITERATORS;
	var ITERATOR$1 = wellKnownSymbol('iterator');
	var KEYS = 'keys';
	var VALUES = 'values';
	var ENTRIES = 'entries';

	var returnThis$1 = function () { return this; };

	var defineIterator = function (Iterable, NAME, IteratorConstructor, next, DEFAULT, IS_SET, FORCED) {
	  createIteratorConstructor(IteratorConstructor, NAME, next);

	  var getIterationMethod = function (KIND) {
	    if (KIND === DEFAULT && defaultIterator) return defaultIterator;
	    if (!BUGGY_SAFARI_ITERATORS$1 && KIND in IterablePrototype) return IterablePrototype[KIND];
	    switch (KIND) {
	      case KEYS: return function keys() { return new IteratorConstructor(this, KIND); };
	      case VALUES: return function values() { return new IteratorConstructor(this, KIND); };
	      case ENTRIES: return function entries() { return new IteratorConstructor(this, KIND); };
	    } return function () { return new IteratorConstructor(this); };
	  };

	  var TO_STRING_TAG = NAME + ' Iterator';
	  var INCORRECT_VALUES_NAME = false;
	  var IterablePrototype = Iterable.prototype;
	  var nativeIterator = IterablePrototype[ITERATOR$1]
	    || IterablePrototype['@@iterator']
	    || DEFAULT && IterablePrototype[DEFAULT];
	  var defaultIterator = !BUGGY_SAFARI_ITERATORS$1 && nativeIterator || getIterationMethod(DEFAULT);
	  var anyNativeIterator = NAME == 'Array' ? IterablePrototype.entries || nativeIterator : nativeIterator;
	  var CurrentIteratorPrototype, methods, KEY;

	  // fix native
	  if (anyNativeIterator) {
	    CurrentIteratorPrototype = objectGetPrototypeOf(anyNativeIterator.call(new Iterable()));
	    if (IteratorPrototype$2 !== Object.prototype && CurrentIteratorPrototype.next) {
	      if ( objectGetPrototypeOf(CurrentIteratorPrototype) !== IteratorPrototype$2) {
	        if (objectSetPrototypeOf) {
	          objectSetPrototypeOf(CurrentIteratorPrototype, IteratorPrototype$2);
	        } else if (typeof CurrentIteratorPrototype[ITERATOR$1] != 'function') {
	          createNonEnumerableProperty(CurrentIteratorPrototype, ITERATOR$1, returnThis$1);
	        }
	      }
	      // Set @@toStringTag to native iterators
	      setToStringTag(CurrentIteratorPrototype, TO_STRING_TAG, true);
	    }
	  }

	  // fix Array#{values, @@iterator}.name in V8 / FF
	  if (DEFAULT == VALUES && nativeIterator && nativeIterator.name !== VALUES) {
	    INCORRECT_VALUES_NAME = true;
	    defaultIterator = function values() { return nativeIterator.call(this); };
	  }

	  // define iterator
	  if ( IterablePrototype[ITERATOR$1] !== defaultIterator) {
	    createNonEnumerableProperty(IterablePrototype, ITERATOR$1, defaultIterator);
	  }

	  // export additional methods
	  if (DEFAULT) {
	    methods = {
	      values: getIterationMethod(VALUES),
	      keys: IS_SET ? defaultIterator : getIterationMethod(KEYS),
	      entries: getIterationMethod(ENTRIES)
	    };
	    if (FORCED) for (KEY in methods) {
	      if (BUGGY_SAFARI_ITERATORS$1 || INCORRECT_VALUES_NAME || !(KEY in IterablePrototype)) {
	        redefine(IterablePrototype, KEY, methods[KEY]);
	      }
	    } else _export({ target: NAME, proto: true, forced: BUGGY_SAFARI_ITERATORS$1 || INCORRECT_VALUES_NAME }, methods);
	  }

	  return methods;
	};

	var ARRAY_ITERATOR = 'Array Iterator';
	var setInternalState = internalState.set;
	var getInternalState = internalState.getterFor(ARRAY_ITERATOR);

	// `Array.prototype.entries` method
	// https://tc39.github.io/ecma262/#sec-array.prototype.entries
	// `Array.prototype.keys` method
	// https://tc39.github.io/ecma262/#sec-array.prototype.keys
	// `Array.prototype.values` method
	// https://tc39.github.io/ecma262/#sec-array.prototype.values
	// `Array.prototype[@@iterator]` method
	// https://tc39.github.io/ecma262/#sec-array.prototype-@@iterator
	// `CreateArrayIterator` internal method
	// https://tc39.github.io/ecma262/#sec-createarrayiterator
	var es_array_iterator = defineIterator(Array, 'Array', function (iterated, kind) {
	  setInternalState(this, {
	    type: ARRAY_ITERATOR,
	    target: toIndexedObject(iterated), // target
	    index: 0,                          // next index
	    kind: kind                         // kind
	  });
	// `%ArrayIteratorPrototype%.next` method
	// https://tc39.github.io/ecma262/#sec-%arrayiteratorprototype%.next
	}, function () {
	  var state = getInternalState(this);
	  var target = state.target;
	  var kind = state.kind;
	  var index = state.index++;
	  if (!target || index >= target.length) {
	    state.target = undefined;
	    return { value: undefined, done: true };
	  }
	  if (kind == 'keys') return { value: index, done: false };
	  if (kind == 'values') return { value: target[index], done: false };
	  return { value: [index, target[index]], done: false };
	}, 'values');

	// https://tc39.github.io/ecma262/#sec-array.prototype-@@unscopables
	addToUnscopables('keys');
	addToUnscopables('values');
	addToUnscopables('entries');

	var arrayMethodIsStrict = function (METHOD_NAME, argument) {
	  var method = [][METHOD_NAME];
	  return !!method && fails(function () {
	    // eslint-disable-next-line no-useless-call,no-throw-literal
	    method.call(null, argument || function () { throw 1; }, 1);
	  });
	};

	var nativeJoin = [].join;

	var ES3_STRINGS = indexedObject != Object;
	var STRICT_METHOD = arrayMethodIsStrict('join', ',');

	// `Array.prototype.join` method
	// https://tc39.github.io/ecma262/#sec-array.prototype.join
	_export({ target: 'Array', proto: true, forced: ES3_STRINGS || !STRICT_METHOD }, {
	  join: function join(separator) {
	    return nativeJoin.call(toIndexedObject(this), separator === undefined ? ',' : separator);
	  }
	});

	var $map = arrayIteration.map;



	var HAS_SPECIES_SUPPORT = arrayMethodHasSpeciesSupport('map');
	// FF49- issue
	var USES_TO_LENGTH$2 = arrayMethodUsesToLength('map');

	// `Array.prototype.map` method
	// https://tc39.github.io/ecma262/#sec-array.prototype.map
	// with adding support of @@species
	_export({ target: 'Array', proto: true, forced: !HAS_SPECIES_SUPPORT || !USES_TO_LENGTH$2 }, {
	  map: function map(callbackfn /* , thisArg */) {
	    return $map(this, callbackfn, arguments.length > 1 ? arguments[1] : undefined);
	  }
	});

	var DatePrototype = Date.prototype;
	var INVALID_DATE = 'Invalid Date';
	var TO_STRING = 'toString';
	var nativeDateToString = DatePrototype[TO_STRING];
	var getTime = DatePrototype.getTime;

	// `Date.prototype.toString` method
	// https://tc39.github.io/ecma262/#sec-date.prototype.tostring
	if (new Date(NaN) + '' != INVALID_DATE) {
	  redefine(DatePrototype, TO_STRING, function toString() {
	    var value = getTime.call(this);
	    // eslint-disable-next-line no-self-compare
	    return value === value ? nativeDateToString.call(this) : INVALID_DATE;
	  });
	}

	var TO_STRING_TAG$1 = wellKnownSymbol('toStringTag');
	var test = {};

	test[TO_STRING_TAG$1] = 'z';

	var toStringTagSupport = String(test) === '[object z]';

	var TO_STRING_TAG$2 = wellKnownSymbol('toStringTag');
	// ES3 wrong here
	var CORRECT_ARGUMENTS = classofRaw(function () { return arguments; }()) == 'Arguments';

	// fallback for IE11 Script Access Denied error
	var tryGet = function (it, key) {
	  try {
	    return it[key];
	  } catch (error) { /* empty */ }
	};

	// getting tag from ES6+ `Object.prototype.toString`
	var classof = toStringTagSupport ? classofRaw : function (it) {
	  var O, tag, result;
	  return it === undefined ? 'Undefined' : it === null ? 'Null'
	    // @@toStringTag case
	    : typeof (tag = tryGet(O = Object(it), TO_STRING_TAG$2)) == 'string' ? tag
	    // builtinTag case
	    : CORRECT_ARGUMENTS ? classofRaw(O)
	    // ES3 arguments fallback
	    : (result = classofRaw(O)) == 'Object' && typeof O.callee == 'function' ? 'Arguments' : result;
	};

	// `Object.prototype.toString` method implementation
	// https://tc39.github.io/ecma262/#sec-object.prototype.tostring
	var objectToString = toStringTagSupport ? {}.toString : function toString() {
	  return '[object ' + classof(this) + ']';
	};

	// `Object.prototype.toString` method
	// https://tc39.github.io/ecma262/#sec-object.prototype.tostring
	if (!toStringTagSupport) {
	  redefine(Object.prototype, 'toString', objectToString, { unsafe: true });
	}

	// a string of all valid unicode whitespaces
	// eslint-disable-next-line max-len
	var whitespaces = '\u0009\u000A\u000B\u000C\u000D\u0020\u00A0\u1680\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u202F\u205F\u3000\u2028\u2029\uFEFF';

	var whitespace = '[' + whitespaces + ']';
	var ltrim = RegExp('^' + whitespace + whitespace + '*');
	var rtrim = RegExp(whitespace + whitespace + '*$');

	// `String.prototype.{ trim, trimStart, trimEnd, trimLeft, trimRight }` methods implementation
	var createMethod$2 = function (TYPE) {
	  return function ($this) {
	    var string = String(requireObjectCoercible($this));
	    if (TYPE & 1) string = string.replace(ltrim, '');
	    if (TYPE & 2) string = string.replace(rtrim, '');
	    return string;
	  };
	};

	var stringTrim = {
	  // `String.prototype.{ trimLeft, trimStart }` methods
	  // https://tc39.github.io/ecma262/#sec-string.prototype.trimstart
	  start: createMethod$2(1),
	  // `String.prototype.{ trimRight, trimEnd }` methods
	  // https://tc39.github.io/ecma262/#sec-string.prototype.trimend
	  end: createMethod$2(2),
	  // `String.prototype.trim` method
	  // https://tc39.github.io/ecma262/#sec-string.prototype.trim
	  trim: createMethod$2(3)
	};

	var trim = stringTrim.trim;


	var $parseInt = global_1.parseInt;
	var hex = /^[+-]?0[Xx]/;
	var FORCED$1 = $parseInt(whitespaces + '08') !== 8 || $parseInt(whitespaces + '0x16') !== 22;

	// `parseInt` method
	// https://tc39.github.io/ecma262/#sec-parseint-string-radix
	var numberParseInt = FORCED$1 ? function parseInt(string, radix) {
	  var S = trim(String(string));
	  return $parseInt(S, (radix >>> 0) || (hex.test(S) ? 16 : 10));
	} : $parseInt;

	// `parseInt` method
	// https://tc39.github.io/ecma262/#sec-parseint-string-radix
	_export({ global: true, forced: parseInt != numberParseInt }, {
	  parseInt: numberParseInt
	});

	// iterable DOM collections
	// flag - `iterable` interface - 'entries', 'keys', 'values', 'forEach' methods
	var domIterables = {
	  CSSRuleList: 0,
	  CSSStyleDeclaration: 0,
	  CSSValueList: 0,
	  ClientRectList: 0,
	  DOMRectList: 0,
	  DOMStringList: 0,
	  DOMTokenList: 1,
	  DataTransferItemList: 0,
	  FileList: 0,
	  HTMLAllCollection: 0,
	  HTMLCollection: 0,
	  HTMLFormElement: 0,
	  HTMLSelectElement: 0,
	  MediaList: 0,
	  MimeTypeArray: 0,
	  NamedNodeMap: 0,
	  NodeList: 1,
	  PaintRequestList: 0,
	  Plugin: 0,
	  PluginArray: 0,
	  SVGLengthList: 0,
	  SVGNumberList: 0,
	  SVGPathSegList: 0,
	  SVGPointList: 0,
	  SVGStringList: 0,
	  SVGTransformList: 0,
	  SourceBufferList: 0,
	  StyleSheetList: 0,
	  TextTrackCueList: 0,
	  TextTrackList: 0,
	  TouchList: 0
	};

	var ITERATOR$2 = wellKnownSymbol('iterator');
	var TO_STRING_TAG$3 = wellKnownSymbol('toStringTag');
	var ArrayValues = es_array_iterator.values;

	for (var COLLECTION_NAME in domIterables) {
	  var Collection = global_1[COLLECTION_NAME];
	  var CollectionPrototype = Collection && Collection.prototype;
	  if (CollectionPrototype) {
	    // some Chrome versions have non-configurable methods on DOMTokenList
	    if (CollectionPrototype[ITERATOR$2] !== ArrayValues) try {
	      createNonEnumerableProperty(CollectionPrototype, ITERATOR$2, ArrayValues);
	    } catch (error) {
	      CollectionPrototype[ITERATOR$2] = ArrayValues;
	    }
	    if (!CollectionPrototype[TO_STRING_TAG$3]) {
	      createNonEnumerableProperty(CollectionPrototype, TO_STRING_TAG$3, COLLECTION_NAME);
	    }
	    if (domIterables[COLLECTION_NAME]) for (var METHOD_NAME in es_array_iterator) {
	      // some Chrome versions have non-configurable methods on DOMTokenList
	      if (CollectionPrototype[METHOD_NAME] !== es_array_iterator[METHOD_NAME]) try {
	        createNonEnumerableProperty(CollectionPrototype, METHOD_NAME, es_array_iterator[METHOD_NAME]);
	      } catch (error) {
	        CollectionPrototype[METHOD_NAME] = es_array_iterator[METHOD_NAME];
	      }
	    }
	  }
	}

	function _typeof(obj) {
	  "@babel/helpers - typeof";

	  if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") {
	    _typeof = function (obj) {
	      return typeof obj;
	    };
	  } else {
	    _typeof = function (obj) {
	      return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj;
	    };
	  }

	  return _typeof(obj);
	}

	function _defineProperty(obj, key, value) {
	  if (key in obj) {
	    Object.defineProperty(obj, key, {
	      value: value,
	      enumerable: true,
	      configurable: true,
	      writable: true
	    });
	  } else {
	    obj[key] = value;
	  }

	  return obj;
	}

	function ownKeys$1(object, enumerableOnly) {
	  var keys = Object.keys(object);

	  if (Object.getOwnPropertySymbols) {
	    var symbols = Object.getOwnPropertySymbols(object);
	    if (enumerableOnly) symbols = symbols.filter(function (sym) {
	      return Object.getOwnPropertyDescriptor(object, sym).enumerable;
	    });
	    keys.push.apply(keys, symbols);
	  }

	  return keys;
	}

	function _objectSpread2(target) {
	  for (var i = 1; i < arguments.length; i++) {
	    var source = arguments[i] != null ? arguments[i] : {};

	    if (i % 2) {
	      ownKeys$1(Object(source), true).forEach(function (key) {
	        _defineProperty(target, key, source[key]);
	      });
	    } else if (Object.getOwnPropertyDescriptors) {
	      Object.defineProperties(target, Object.getOwnPropertyDescriptors(source));
	    } else {
	      ownKeys$1(Object(source)).forEach(function (key) {
	        Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key));
	      });
	    }
	  }

	  return target;
	}

	//
	// setupFontAwesome
	//
	var setupFontAwesome = function setupFontAwesome() {
	  if (!window.FontDetect) return;

	  if (!FontDetect.isFontLoaded("14px/1 FontAwesome")) {
	    $(".use-icon-font").hide();
	    $(".use-icon-png").show();
	  }
	}; //
	// setupBuilder
	//


	var setupBuilder = function () {
	  var buildFilterOperators = function buildFilterOperators(type) {
	    if (!["date", "daterange"].includes(type)) return undefined;
	    var operators = ["equal", "not_equal", "less", "less_or_equal", "greater", "greater_or_equal", "is_empty", "is_not_empty"];
	    type === "daterange" && operators.push("contain");
	    return operators;
	  };

	  var typeaheadProperties = function typeaheadProperties(urlSuffix, layoutId, instanceId) {
	    return {
	      input: function input(container, rule, input_name) {
	        return "<input class=\"typeahead_text\" type=\"text\" name=\"".concat(input_name, "_text\">\n      <input class=\"typeahead_hidden\" type=\"hidden\" name=\"").concat(input_name, "\"></input>");
	      },
	      valueSetter: function valueSetter($rule, value, filter, operator, data) {
	        $rule.find(".typeahead_text").val(data.text);
	        $rule.find(".typeahead_hidden").val(value);
	      },
	      onAfterCreateRuleInput: function onAfterCreateRuleInput($rule) {
	        var $ruleInputText = $("#".concat($rule.attr("id"), " .rule-value-container input[type=\"text\"]"));
	        var $ruleInputHidden = $("#".concat($rule.attr("id"), " .rule-value-container input[type=\"hidden\"]"));
	        $ruleInputText.attr("autocomplete", "off");
	        $ruleInputText.typeahead({
	          delay: 100,
	          matcher: function matcher() {
	            return true;
	          },
	          sorter: function sorter(items) {
	            return items;
	          },
	          afterSelect: function afterSelect(selected) {
	            if (_typeof(selected) === "object") {
	              $ruleInputHidden.val(selected.id);
	            } else {
	              $ruleInputHidden.val(selected);
	            }
	          },
	          source: function source(query, process) {
	            return $.ajax({
	              type: "GET",
	              url: "/".concat(layoutId, "/match/layout/").concat(urlSuffix),
	              data: {
	                q: query,
	                oi: instanceId
	              },
	              success: function success(result) {
	                process(result);
	              },
	              dataType: "json"
	            });
	          }
	        });
	      }
	    };
	  };

	  var ragProperties = {
	    input: "select",
	    values: {
	      b_red: "Red",
	      c_amber: "Amber",
	      c_yellow: "Yellow",
	      d_green: "Green",
	      a_grey: "Grey",
	      e_purple: "Purple"
	    }
	  };

	  var buildFilter = function buildFilter(builderConfig, col) {
	    return _objectSpread2({
	      id: col.filterId,
	      label: col.label,
	      type: "string",
	      operators: buildFilterOperators(col.type)
	    }, col.type === "rag" ? ragProperties : col.hasFilterTypeahead ? typeaheadProperties(col.urlSuffix, builderConfig.layoutId, col.instanceId) : {});
	  };

	  var makeUpdateFilter = function makeUpdateFilter() {
	    window.UpdateFilter = function (builder) {
	      var res = builder.queryBuilder("getRules");
	      $("#filter").val(JSON.stringify(res, null, 2));
	    };
	  };

	  var operators = [{
	    type: "equal",
	    accept_values: true,
	    apply_to: ["string", "number", "datetime"]
	  }, {
	    type: "not_equal",
	    accept_values: true,
	    apply_to: ["string", "number", "datetime"]
	  }, {
	    type: "less",
	    accept_values: true,
	    apply_to: ["string", "number", "datetime"]
	  }, {
	    type: "less_or_equal",
	    accept_values: true,
	    apply_to: ["string", "number", "datetime"]
	  }, {
	    type: "greater",
	    accept_values: true,
	    apply_to: ["string", "number", "datetime"]
	  }, {
	    type: "greater_or_equal",
	    accept_values: true,
	    apply_to: ["string", "number", "datetime"]
	  }, {
	    type: "contains",
	    accept_values: true,
	    apply_to: ["datetime", "string"]
	  }, {
	    type: "not_contains",
	    accept_values: true,
	    apply_to: ["datetime", "string"]
	  }, {
	    type: "begins_with",
	    accept_values: true,
	    apply_to: ["string"]
	  }, {
	    type: "not_begins_with",
	    accept_values: true,
	    apply_to: ["string"]
	  }, {
	    type: "is_empty",
	    accept_values: false,
	    apply_to: ["string", "number", "datetime"]
	  }, {
	    type: "is_not_empty",
	    accept_values: false,
	    apply_to: ["string", "number", "datetime"]
	  }, {
	    type: "changed_after",
	    nb_inputs: 1,
	    accept_values: true,
	    multiple: false,
	    apply_to: ["string", "number", "datetime"]
	  }];

	  var setupBuilder = function setupBuilder(builderEl) {
	    var builderConfig = JSON.parse($(builderEl).html());
	    if (builderConfig.filterNotDone) makeUpdateFilter();
	    $("#builder".concat(builderConfig.builderId)).queryBuilder({
	      showPreviousValues: builderConfig.showPreviousValues,
	      filters: builderConfig.filters.map(function (col) {
	        return buildFilter(builderConfig, col);
	      }),
	      operators: operators,
	      lang: {
	        operators: {
	          changed_after: "changed on or after"
	        }
	      }
	    });
	  };

	  var setupAllBuilders = function setupAllBuilders(context) {
	    $('script[id^="builder_json_"]', context).each(function (i, builderEl) {
	      setupBuilder(builderEl);
	    });
	  };

	  var setupTypeahead = function setupTypeahead(context) {
	    $(document, context).on("input", ".typeahead_text", function () {
	      var value = $(this).val();
	      $(this).next(".typeahead_hidden").val(value);
	    });
	  };

	  return function (context) {
	    setupAllBuilders(context);
	    setupTypeahead(context);
	  };
	}(); //
	// setupCalendar
	//


	var setupCalendar = function () {
	  var initCalendar = function initCalendar(context) {
	    var calendarEl = $("#calendar", context);
	    if (!calendarEl.length) return false;
	    var options = {
	      events_source: "/".concat(calendarEl.attr("data-event-source"), "/data_calendar/").concat(new Date().getTime()),
	      view: calendarEl.data("view"),
	      tmpl_path: "/tmpls/",
	      tmpl_cache: false,
	      onAfterEventsLoad: function onAfterEventsLoad(events) {
	        if (!events) {
	          return;
	        }

	        var list = $("#eventlist");
	        list.html("");
	        $.each(events, function (key, val) {
	          $(document.createElement("li")).html("<a href=\"".concat(val.url, "\">").concat(val.title, "</a>")).appendTo(list);
	        });
	      },
	      onAfterViewLoad: function onAfterViewLoad(view) {
	        $("#caltitle").text(this.getTitle());
	        $(".btn-group button").removeClass("active");
	        $("button[data-calendar-view=\"".concat(view, "\"]")).addClass("active");
	      },
	      classes: {
	        months: {
	          general: "label"
	        }
	      }
	    };
	    var day = calendarEl.data("calendar-day-ymd");

	    if (day) {
	      options.day = day;
	    }

	    return calendarEl.calendar(options);
	  };

	  var setupButtons = function setupButtons(calendar, context) {
	    $(".btn-group button[data-calendar-nav]", context).each(function () {
	      var $this = $(this);
	      $this.click(function () {
	        calendar.navigate($this.data("calendar-nav"));
	      });
	    });
	    $(".btn-group button[data-calendar-view]", context).each(function () {
	      var $this = $(this);
	      $this.click(function () {
	        calendar.view($this.data("calendar-view"));
	      });
	    });
	  };

	  var setupSpecifics = function setupSpecifics(calendar, context) {
	    $("#first_day", context).change(function () {
	      var value = $(this).val();
	      value = value.length ? parseInt(value) : null;
	      calendar.setOptions({
	        first_day: value
	      });
	      calendar.view();
	    });
	    $("#language", context).change(function () {
	      calendar.setLanguage($(this).val());
	      calendar.view();
	    });
	    $("#events-in-modal", context).change(function () {
	      var val = $(this).is(":checked") ? $(this).val() : null;
	      calendar.setOptions({
	        modal: val
	      });
	    });
	    $("#events-modal .modal-header, #events-modal .modal-footer", context).click(function () {});
	  };

	  return function (context) {
	    var calendar = initCalendar(context);

	    if (calendar) {
	      setupButtons(calendar, context);
	      setupSpecifics(calendar, context);
	      setupFontAwesome();
	    }
	  };
	}(); //
	// setupCurvalModal
	//


	var setupCurvalModal = function () {
	  var curvalModalValidationSucceeded = function curvalModalValidationSucceeded(form, values, context) {
	    var form_data = form.serialize();
	    var modal_field_ids = form.data("modal-field-ids");
	    var col_id = form.data("curval-id");
	    var instance_name = form.data("instance-name");
	    var guid = form.data("guid");
	    var hidden_input = $("<input>", context).attr({
	      type: "hidden",
	      name: "field" + col_id,
	      value: form_data
	    });
	    var $formGroup = $("div[data-column-id=" + col_id + "]", context);
	    var valueSelector = $formGroup.data("value-selector");

	    if (valueSelector === "noshow") {
	      var row_cells = $('<tr class="curval_item">', context);
	      jQuery.map(modal_field_ids, function (element) {
	        var control = form.find('[data-column-id="' + element + '"]');
	        var value = getFieldValues(control);
	        value = values["field" + element];
	        value = $("<div />", context).text(value).html();
	        row_cells.append($('<td class="curval-inner-text">', context).append(value));
	      });
	      var links = $("<td>\n        <a class=\"curval-modal\" style=\"cursor:pointer\" data-layout-id=\"".concat(col_id, " data-instance-name=").concat(instance_name, ">edit</a> | <a class=\"curval_remove\" style=\"cursor:pointer\">remove</a>\n      </td>"), context);
	      row_cells.append(links.append(hidden_input));

	      if (guid) {
	        var hidden = $('input[data-guid="' + guid + '"]', context).val(form_data);
	        hidden.closest(".curval_item").replaceWith(row_cells);
	      } else {
	        $("#curval_list_".concat(col_id), context).find("tbody").prepend(row_cells);
	      }
	    } else if (valueSelector === "dropdown") {
	      var $widget = $formGroup.find(".select-widget").first();
	      var multi = $widget.hasClass("multi");
	      var $currentItems = $formGroup.find(".current [data-list-item]");
	      var $search = $formGroup.find(".current .search");
	      var $answersList = $formGroup.find(".available");

	      if (!multi) {
	        /* Deselect current selected value */
	        $currentItems.attr("hidden", "");
	        $answersList.find("li input").prop("checked", false);
	      }

	      var textValue = jQuery.map(modal_field_ids, function (element) {
	        var value = values["field" + element];
	        return $("<div />").text(value).html();
	      }).join(", ");
	      guid = window.guid();
	      var id = "field".concat(col_id, "_").concat(guid);
	      var deleteButton = multi ? '<button class="close select-widget-value__delete" aria-hidden="true" aria-label="delete" title="delete" tabindex="-1">&times;</button>' : "";
	      $search.before("<li data-list-item=\"".concat(id, "\">").concat(textValue).concat(deleteButton, "</li>"));
	      var inputType = multi ? "checkbox" : "radio";
	      $answersList.append("<li class=\"answer\">\n        <span class=\"control\">\n            <label id=\"".concat(id, "_label\" for=\"").concat(id, "\">\n                <input id=\"").concat(id, "\" name=\"field").concat(col_id, "\" type=\"").concat(inputType, "\" value=\"").concat(form_data, "\" class=\"").concat(multi ? "" : "visually-hidden", "\" checked aria-labelledby=\"").concat(id, "_label\">\n                <span>").concat(textValue, "</span>\n            </label>\n        </span>\n        <span class=\"details\">\n            <a class=\"curval_remove\" style=\"cursor:pointer\">remove</a>\n        </span>\n      </li>"));
	      /* Reinitialize widget */

	      setupSelectWidgets($formGroup);
	    } else if (valueSelector === "typeahead") {
	      var $hiddenInput = $formGroup.find("input[name=field".concat(col_id, "]"));
	      var $typeaheadInput = $formGroup.find("input[name=field".concat(col_id, "_typeahead]"));
	      var textValueHead = jQuery.map(modal_field_ids, function (element) {
	        var value = values["field" + element];
	        return $("<div />").text(value).html();
	      }).join(", ");
	      $hiddenInput.val(form_data);
	      $typeaheadInput.val(textValueHead);
	    }

	    $(".modal.in", context).modal("hide");
	  };

	  var curvalModalValidationFailed = function curvalModalValidationFailed(form, errorMessage) {
	    form.find(".alert").text(errorMessage).removeAttr("hidden");
	    form.parents(".modal-content").get(0).scrollIntoView();
	    form.find("button[type=submit]").prop("disabled", false);
	  };

	  var setupAddButton = function setupAddButton(context) {
	    $(document, context).on("mousedown", ".curval-modal", function (e) {
	      var layout_id = $(e.target).data("layout-id");
	      var instance_name = $(e.target).data("instance-name");
	      var current_id = $(e.target).data("current-id");
	      var hidden = $(e.target).closest(".curval_item").find("input[name=field".concat(layout_id, "]"));
	      var form_data = hidden.val();
	      var mode = hidden.length ? "edit" : "add";
	      var guid;

	      if (mode === "edit") {
	        guid = hidden.data("guid");

	        if (!guid) {
	          guid = window.guid();
	          hidden.attr("data-guid", guid);
	        }
	      }

	      var m = $("#curval_modal", context);
	      m.find(".modal-body").text("Loading...");
	      var url = current_id ? "/record/".concat(current_id) : "/".concat(instance_name, "/record/");
	      m.find(".modal-body").load("".concat(url, "?include_draft&modal=").concat(layout_id, "&").concat(form_data), function () {
	        if (mode === "edit") {
	          m.find("form").data("guid", guid);
	        }

	        Linkspace.init(m);
	      });
	      m.on("focus", ".datepicker", function () {
	        $(this).datepicker({
	          format: m.attr("data-dateformat-datepicker"),
	          autoclose: true
	        });
	      });
	      m.modal();
	    });
	  };

	  var setupSubmit = function setupSubmit(context) {
	    $("#curval_modal", context).on("submit", ".curval-edit-form", function (e) {
	      e.preventDefault();
	      var form = $(this);
	      var form_data = form.serialize();
	      form.addClass("edit-form--validating");
	      form.find(".alert").attr("hidden", "");
	      $.post(form.attr("action") + "?validate&include_draft", form_data, function (data) {
	        if (data.error === 0) {
	          curvalModalValidationSucceeded(form, data.values);
	        } else {
	          var errorMessage = data.error === 1 ? data.message : "Oops! Something went wrong.";
	          curvalModalValidationFailed(form, errorMessage);
	        }
	      }, "json").fail(function (jqXHR, textstatus, errorthrown) {
	        var errorMessage = "Oops! Something went wrong: ".concat(textstatus, ": ").concat(errorthrown);
	        curvalModalValidationFailed(form, errorMessage);
	      }).always(function () {
	        form.removeClass("edit-form--validating");
	      });
	    });
	  };

	  var setupRemoveCurval = function setupRemoveCurval(context) {
	    $(".curval_group", context).on("click", ".curval_remove", function () {
	      $(this).closest(".curval_item").remove();
	    });
	    $(".select-widget", context).on("click", ".curval_remove", function () {
	      var fieldId = $(this).closest(".answer").find("input").prop("id");
	      $(this).closest(".select-widget").find(".current li[data-list-item=".concat(fieldId, "]")).remove();
	      $(this).closest(".answer").remove();
	    });
	  };

	  return function (context) {
	    setupAddButton(context);
	    setupSubmit(context);
	    setupRemoveCurval(context);
	  };
	}(); //
	// setupDatePicker
	//


	var setupDatePicker = function () {
	  var setupDatePickers = function setupDatePickers(context) {
	    $(".datepicker", context).datepicker({
	      format: $(document.body).data("config-dataformat-datepicker"),
	      autoclose: true
	    });
	  };

	  var setupDateRange = function setupDateRange(context) {
	    $(".input-daterange input.from", context).each(function () {
	      $(this).on("changeDate", function () {
	        var toDatepicker = $(this).parents(".input-daterange").find(".datepicker.to");

	        if (!toDatepicker.val()) {
	          toDatepicker.datepicker("update", $(this).datepicker("getDate"));
	        }
	      });
	    });
	  };

	  var setupRemoveDatePicker = function setupRemoveDatePicker(context) {
	    $(document, context).on("click", ".remove_datepicker", function () {
	      var dp = ".datepicker" + $(this).data("field");
	      $(dp).datepicker("destroy"); //eslint-disable-next-line no-alert

	      alert("Date selector has been disabled for this field");
	    });
	  };

	  return function (context) {
	    setupDatePickers(context);
	    setupDateRange(context);
	    setupRemoveDatePicker(context);
	  };
	}(); //
	// setupEdit
	//


	var setupEdit = function () {
	  var setupCloneAndRemove = function setupCloneAndRemove(context) {
	    $(document, context).on("click", ".cloneme", function () {
	      var parent = $(this).parents(".input_holder");
	      var cloned = parent.clone();
	      cloned.removeAttr("id").insertAfter(parent);
	      cloned.find(":text").val("");
	      cloned.find(".datepicker").datepicker({
	        format: parent.attr("data-dateformat-datepicker"),
	        autoclose: true
	      });
	    });
	    $(document, context).on("click", ".removeme", function () {
	      var parent = $(this).parents(".input_holder");

	      if (parent.siblings(".input_holder").length > 0) {
	        parent.remove();
	      }
	    });
	  };

	  var setupHelpTextModal = function setupHelpTextModal(context) {
	    $("#helptext_modal", context).on("show.bs.modal", function (e) {
	      var loadurl = $(e.relatedTarget).data("load-url");
	      $(this).find(".modal-body").load(loadurl);
	    });
	    $(document, context).on("click", ".more-info", function (e) {
	      var record_id = $(e.target).data("record-id");
	      var m = $("#readmore_modal", context);
	      m.find(".modal-body").text("Loading...");
	      m.find(".modal-body").load("/record_body/" + record_id);
	      /* Trigger focus restoration on modal close */

	      m.one("show.bs.modal", function (showEvent) {
	        /* Only register focus restorer if modal will actually get shown */
	        if (showEvent.isDefaultPrevented()) {
	          return;
	        }

	        m.one("hidden.bs.modal", function () {
	          $(e.target, context).is(":visible") && $(e.target, context).trigger("focus");
	        });
	      });
	      /* Stop propagation of the escape key, as may have side effects, like closing select widgets. */

	      m.one("keyup", function (e) {
	        if (e.keyCode == 27) {
	          e.stopPropagation();
	        }
	      });
	      m.modal();
	    });
	  };

	  var setupTypeahead = function setupTypeahead(context) {
	    $('input[type="text"][id^="typeahead_"]', context).each(function (i, typeaheadEl) {
	      $(typeaheadEl, context).change(function () {
	        if (!$(this).val()) {
	          $("#".concat(typeaheadEl.id, "_value"), context).val("");
	        }
	      });
	      $(typeaheadEl, context).typeahead({
	        delay: 500,
	        matcher: function matcher() {
	          return true;
	        },
	        sorter: function sorter(items) {
	          return items;
	        },
	        afterSelect: function afterSelect(selected) {
	          $("#".concat(typeaheadEl.id, "_value"), context).val(selected.id);
	        },
	        source: function source(query, process) {
	          return $.ajax({
	            type: "GET",
	            url: "/".concat($(typeaheadEl, context).data("layout-id"), "/match/layout/").concat($(typeaheadEl).data("typeahead-id")),
	            data: {
	              q: query
	            },
	            success: function success(result) {
	              process(result);
	            },
	            dataType: "json"
	          });
	        }
	      });
	    });
	  };

	  return function (context) {
	    setupCloneAndRemove(context);
	    setupHelpTextModal(context);
	    setupCurvalModal(context);
	    setupDatePicker(context);
	    setupTypeahead(context);
	  };
	}(); //
	// setupGlobe
	//


	var setupGlobe = function () {
	  var initGlobe = function initGlobe(context) {
	    var globeEl = $("#globe", context);
	    if (!globeEl.length) return;
	    Plotly.setPlotConfig({
	      locale: "en-GB"
	    });
	    var data = JSON.parse(base64.decode(globeEl.attr("data-globe")));
	    var layout = {
	      margin: {
	        t: 10,
	        l: 10,
	        r: 10,
	        b: 10
	      },
	      geo: {
	        scope: "world",
	        showcountries: true,
	        countrycolor: "grey",
	        resolution: 110
	      }
	    };
	    var options = {
	      showLink: false,
	      displaylogo: false,
	      modeBarButtonsToRemove: ["sendDataToCloud"],
	      topojsonURL: "".concat(globeEl.attr("data-url"), "/")
	    };
	    Plotly.newPlot("globe", data, layout, options);
	  };

	  return function (context) {
	    initGlobe(context);
	  };
	}(); // setupGraph


	var setupGraph = function () {
	  var makeSeriesDefaults = function makeSeriesDefaults() {
	    return {
	      bar: {
	        renderer: $.jqplot.BarRenderer,
	        rendererOptions: {
	          shadow: false,
	          fillToZero: true,
	          barMinWidth: 10
	        },
	        pointLabels: {
	          show: false,
	          hideZeros: true
	        }
	      },
	      donut: {
	        renderer: $.jqplot.DonutRenderer,
	        rendererOptions: {
	          sliceMargin: 3,
	          showDataLabels: true,
	          dataLabels: "value",
	          shadow: false
	        }
	      },
	      pie: {
	        renderer: $.jqplot.PieRenderer,
	        rendererOptions: {
	          showDataLabels: true,
	          dataLabels: "value",
	          shadow: false
	        }
	      },
	      "default": {
	        pointLabels: {
	          show: false
	        }
	      }
	    };
	  };

	  var do_plot = function do_plot(plotData, options_in) {
	    var ticks = plotData.xlabels;
	    var plotOptions = {};
	    var showmarker = options_in.type == "line" ? true : false;
	    plotOptions.highlighter = {
	      showMarker: showmarker,
	      tooltipContentEditor: function tooltipContentEditor(str, pointIndex, index, plot) {
	        return plot._plotData[pointIndex][index][1];
	      }
	    };
	    var seriesDefaults = makeSeriesDefaults();

	    if (options_in.type in seriesDefaults) {
	      plotOptions.seriesDefaults = seriesDefaults[options_in.type];
	    } else {
	      plotOptions.seriesDefaults = seriesDefaults["default"];
	    }

	    if (options_in.type != "donut" && options_in.type != "pie") {
	      plotOptions.series = plotData.labels;
	      plotOptions.axes = {
	        xaxis: {
	          renderer: $.jqplot.CategoryAxisRenderer,
	          ticks: ticks,
	          label: options_in.x_axis_name,
	          labelRenderer: $.jqplot.CanvasAxisLabelRenderer
	        },
	        yaxis: {
	          label: options_in.y_axis_label,
	          labelRenderer: $.jqplot.CanvasAxisLabelRenderer
	        }
	      };

	      if (plotData.options.y_max) {
	        plotOptions.axes.yaxis.max = plotData.options.y_max;
	      }

	      if (plotData.options.is_metric) {
	        plotOptions.axes.yaxis.tickOptions = {
	          formatString: "%d%"
	        };
	      }

	      plotOptions.axesDefaults = {
	        tickRenderer: $.jqplot.CanvasAxisTickRenderer,
	        tickOptions: {
	          angle: -30,
	          fontSize: "8pt"
	        }
	      };
	    }

	    plotOptions.stackSeries = options_in.stackseries;
	    plotOptions.legend = {
	      renderer: $.jqplot.EnhancedLegendRenderer,
	      show: options_in.showlegend,
	      location: "e",
	      placement: "outside"
	    };
	    $.jqplot("chartdiv".concat(options_in.id), plotData.points, plotOptions);
	  };

	  var ajaxDataRenderer = function ajaxDataRenderer(url) {
	    var ret = null;
	    $.ajax({
	      async: false,
	      url: url,
	      dataType: "json",
	      success: function success(data) {
	        ret = data;
	      }
	    });
	    return ret;
	  };

	  var setupCharts = function setupCharts(chartDivs) {
	    setupFontAwesome();
	    $.jqplot.config.enablePlugins = true;
	    chartDivs.each(function (i, val) {
	      var data = $(val).data();
	      var time = new Date().getTime();
	      var jsonurl = "/".concat(data.layoutId, "/data_graph/").concat(data.graphId, "/").concat(time);
	      var plotData = ajaxDataRenderer(jsonurl);
	      var options_in = {
	        type: data.graphType,
	        x_axis_name: data.xAxisName,
	        y_axis_label: data.yAxisLabel,
	        stackseries: data.stackseries,
	        showlegend: data.showlegend,
	        id: data.graphId
	      };
	      do_plot(plotData, options_in);
	    });
	  };

	  var initGraph = function initGraph(context) {
	    var chartDiv = $("#chartdiv", context);
	    var chartDivs = $("[id^=chartdiv]", context);
	    if (!chartDiv.length && chartDivs.length) setupCharts(chartDivs);
	  };

	  return function (context) {
	    initGraph(context);
	  };
	}(); //
	// setupLayout
	//


	var setupLayout = function () {
	  var setupDemoButtons = function setupDemoButtons(context) {
	    var demo_delete = function demo_delete() {
	      var ref = $("#jstree_demo_div", context).jstree(true),
	          sel = ref.get_selected();

	      if (!sel.length) {
	        return false;
	      }

	      ref.delete_node(sel);
	    };

	    $("#btnDeleteNode", context).click(demo_delete);

	    var demo_create = function demo_create() {
	      var ref = $("#jstree_demo_div", context).jstree(true),
	          sel = ref.get_selected();

	      if (sel.length) {
	        sel = sel[0];
	      } else {
	        sel = "#";
	      }

	      sel = ref.create_node(sel, {
	        type: "file"
	      });

	      if (sel) {
	        ref.edit(sel);
	      }
	    };

	    $("#btnAddNode", context).click(demo_create);

	    var demo_rename = function demo_rename() {
	      var ref = $("#jstree_demo_div", context).jstree(true),
	          sel = ref.get_selected();

	      if (!sel.length) {
	        return false;
	      }

	      sel = sel[0];
	      ref.edit(sel);
	    };

	    $("#btnRenameNode", context).click(demo_rename);
	  }; // No longer used? Where is #selectall ?


	  var setupSelectAll = function setupSelectAll(context) {
	    $("#selectall", context).click(function () {
	      if ($(".check_perm:checked", context).length == 7) {
	        $(".check_perm", context).prop("checked", false);
	      } else {
	        $(".check_perm", context).prop("checked", true);
	      }
	    });
	  };

	  var setupSortableHandle = function setupSortableHandle(context) {
	    if (!$(".sortable", context).length) return;
	    $(".sortable", context).sortable({
	      handle: ".drag"
	    });
	  };

	  var setupTreeDemo = function setupTreeDemo(context) {
	    var treeEl = $("#jstree_demo_div", context);
	    if (!treeEl.length) return;
	    treeEl.jstree({
	      core: {
	        check_callback: true,
	        force_text: true,
	        themes: {
	          stripes: true
	        },
	        data: {
	          url: function url() {
	            return "/".concat(treeEl.data("layout-identifier"), "/tree").concat(new Date().getTime(), "/").concat(treeEl.data("column-id"), "?");
	          },
	          data: function data(node) {
	            return {
	              id: node.id
	            };
	          }
	        }
	      }
	    });
	  };

	  var setupDropdownValues = function setupDropdownValues(context) {
	    $("div#legs", context).on("click", ".add", function (event) {
	      $(event.currentTarget, context).closest("#legs").find(".sortable").append("\n          <div class=\"request-row\">\n            <p>\n              <input type=\"hidden\" name=\"enumval_id\">\n              <input type=\"text\" class=\"form-control\" style=\"width:80%; display:inline\" name=\"enumval\">\n              <button type=\"button\" class=\"close closeme\" style=\"float:none\">&times;</button>\n              <span class=\"fa fa-hand-paper-o fa-lg use-icon-font close drag\" style=\"float:none\"></span>\n            </p>\n          </div>\n      ");
	      $(".sortable", context).sortable("refresh");
	    });
	    $("div#legs").on("click", ".closeme", function (event) {
	      var count = $(".request-row", context).length;
	      if (count < 2) return;
	      $(event.currentTarget, context).parents(".request-row").remove();
	    });
	  };

	  var setupTableDropdown = function setupTableDropdown(context) {
	    $("#refers_to_instance_id", context).change(function (event) {
	      var divid = "#instance_fields_".concat($(event.currentTarget, context).val());
	      $(".instance_fields", context).hide();
	      $(divid, context).show();
	    });
	  };

	  var setupAutoValueField = function setupAutoValueField(context) {
	    $("#related_field_id", context).change(function (event) {
	      var divid = $(event.currentTarget).find(":selected").data("instance_id");
	      $(".autocur_instance", context).hide();
	      $("#autocur_instance_".concat(divid), context).show();
	    });
	    $("#filval_related_field_id", context).change(function () {
	      var divid = $(this).val();
	      $(".filval_curval", context).hide();
	      $("#filval_curval_" + divid, context).show();
	    });
	  };

	  var setupJsonFilters = function setupJsonFilters(context) {
	    $('div[id^="builder"]', context).each(function (i, builderEl) {
	      var filterBase = $(builderEl).data("filter-base");
	      if (!filterBase) return;
	      var data = base64.decode(filterBase);
	      $(builderEl).queryBuilder("setRules", JSON.parse(data));
	    });
	  };

	  var setupDisplayConditionsBuilder = function setupDisplayConditionsBuilder(context) {
	    var conditionsBuilder = $("#displayConditionsBuilder", context);
	    if (!conditionsBuilder.length) return;
	    var builderData = conditionsBuilder.data();
	    conditionsBuilder.queryBuilder({
	      filters: builderData.filters,
	      allow_groups: 0,
	      operators: [{
	        type: "equal",
	        accept_values: true,
	        apply_to: ["string"]
	      }, {
	        type: "contains",
	        accept_values: true,
	        apply_to: ["string"]
	      }, {
	        type: "not_equal",
	        accept_values: true,
	        apply_to: ["string"]
	      }, {
	        type: "not_contains",
	        accept_values: true,
	        apply_to: ["string"]
	      }]
	    });

	    if (builderData.filterBase) {
	      var data = base64.decode(builderData.filterBase);
	      conditionsBuilder.queryBuilder("setRules", JSON.parse(data));
	    }
	  };

	  var setupSubmitSave = function setupSubmitSave(context) {
	    $("#submit_save", context).click(function () {
	      var res = $("#displayConditionsBuilder", context).queryBuilder("getRules");
	      $("#displayConditions", context).val(JSON.stringify(res, null, 2));
	      var current_builder = "#builder".concat($("#refers_to_instance_id", context).val());
	      var jstreeDemoDivEl = $("#jstree_demo_div", context);

	      if (jstreeDemoDivEl.length && jstreeDemoDivEl.is(":visible")) {
	        var v = jstreeDemoDivEl.jstree(true).get_json("#", {
	          flat: false
	        });
	        var mytext = JSON.stringify(v);
	        var data = jstreeDemoDivEl.data();
	        $.ajax({
	          async: false,
	          type: "POST",
	          url: "/".concat(data.layoutIdentifier, "/tree/").concat(data.columnId),
	          data: {
	            data: mytext,
	            csrf_token: data.csrfToken
	          }
	        }).done(function () {
	          // eslint-disable-next-line no-alert
	          alert("Tree has been updated");
	        });
	        return true;
	      } else if ($(current_builder, context).is(":visible")) {
	        UpdateFilter($(current_builder, context));
	      }

	      return true;
	    });
	  };

	  var setupType = function setupType(context) {
	    $("#type", context).on("change", function () {
	      var $mf = $("#manage-fields", context);
	      var current_type = $mf.data("column-type");
	      var new_type = $(this).val();
	      $mf.removeClass("column-type-" + current_type);
	      $mf.addClass("column-type-" + new_type);
	      $mf.data("column-type", new_type);

	      if (new_type == "rag" || new_type == "intgr" || new_type == "person") {
	        $("#checkbox-multivalue", context).hide();
	      } else {
	        $("#checkbox-multivalue", context).show();
	      }
	    }).trigger("change");
	  };

	  var setupNotify = function setupNotify(context) {
	    $("#notify_on_selection", context).on("change", function () {
	      if ($(this).prop('checked')) {
	        $("#notify-options", context).show();
	      } else {
	        $("#notify-options", context).hide();
	      }
	    }).trigger("change");
	  };

	  return function (context) {
	    setupDemoButtons(context);
	    setupSelectAll(context);
	    setupSortableHandle(context);
	    setupTreeDemo(context);
	    setupDropdownValues(context);
	    setupTableDropdown(context);
	    setupAutoValueField(context);
	    setupJsonFilters(context);
	    setupDisplayConditionsBuilder(context);
	    setupSubmitSave(context);
	    setupType(context);
	    setupNotify(context);
	  };
	}(); //
	// setupLogin
	//


	var setupLogin = function () {
	  var setupOpenModalOnLoad = function setupOpenModalOnLoad(id, context) {
	    var modalEl = $(id, context);

	    if (modalEl.data("open-on-load")) {
	      modalEl.modal("show");
	    }
	  };

	  return function (context) {
	    setupOpenModalOnLoad("#modalregister", context);
	    setupOpenModalOnLoad("#modal-reset-password", context);
	  };
	}(); //
	// setupMetric
	//


	var setupMetric = function () {
	  var setupMetricModal = function setupMetricModal(context) {
	    var modalEl = $("#modal_metric", context);
	    if (!modalEl.length) return;
	    modalEl.on("show.bs.modal", function (event) {
	      var button = $(event.relatedTarget);
	      var metric_id = button.data("metric_id");
	      $("#metric_id", context).val(metric_id);

	      if (metric_id) {
	        $("#delete_metric", context).show();
	      } else {
	        $("#delete_metric", context).hide();
	      }

	      var target_value = button.data("target_value");
	      $("#target_value", context).val(target_value);
	      var x_axis_value = button.data("x_axis_value");
	      $("#x_axis_value", context).val(x_axis_value);
	      var y_axis_grouping_value = button.data("y_axis_grouping_value");
	      $("#y_axis_grouping_value", context).val(y_axis_grouping_value);
	    });
	  };

	  return function (context) {
	    setupMetricModal(context);
	  };
	}(); //
	// setupMyGraphs
	//


	var setupMyGraphs = function () {
	  var setupDataTable = function setupDataTable(context) {
	    var dtableEl = $("#mygraphs-table", context);
	    if (!dtableEl.length) return;
	    dtableEl.dataTable({
	      columnDefs: [{
	        targets: 0,
	        orderable: false
	      }],
	      pageLength: 50,
	      order: [[1, "asc"]]
	    });
	  };

	  return function (context) {
	    setupDataTable(context);
	  };
	}(); //
	// setupPlaceholder
	//


	var setupPlaceholder = function () {
	  var setupPlaceholder = function setupPlaceholder(context) {
	    $("input, text", context).placeholder();
	  };

	  return function (context) {
	    setupPlaceholder(context);
	  };
	}(); //
	// setupPopover
	//


	var setupPopover = function () {
	  var setupPopover = function setupPopover(context) {
	    $('[data-toggle="popover"]', context).popover({
	      placement: "auto",
	      html: true
	    });
	  };

	  return function (context) {
	    setupPopover(context);
	  };
	}(); //
	// setupPurge
	//


	var setupPurge = function () {
	  var setupSelectAll = function setupSelectAll(context) {
	    $("#selectall", context).click(function () {
	      $(".record_selected", context).prop("checked", this.checked);
	    });
	  };

	  return function (context) {
	    setupSelectAll(context);
	  };
	}(); //
	// setupTable
	//


	var setupTable = function () {
	  var setupSendemailModal = function setupSendemailModal(context) {
	    $("#modal_sendemail", context).on("show.bs.modal", function (event) {
	      var button = $(event.relatedTarget);
	      var peopcol_id = button.data("peopcol_id");
	      $("#modal_sendemail_peopcol_id").val(peopcol_id);
	    });
	  };

	  var setupHelptextModal = function setupHelptextModal(context) {
	    $("#modal_helptext", context).on("show.bs.modal", function (event) {
	      var button = $(event.relatedTarget);
	      var col_name = button.data("col_name");
	      $("#modal_helptext", context).find(".modal-title").text(col_name);
	      var col_id = button.data("col_id");
	      $.get("/helptext/" + col_id, function (data) {
	        $("#modal_helptext", context).find(".modal-body").html(data);
	      });
	    });
	  };

	  var setupDataTable = function setupDataTable(context) {
	    if (!$("#data-table", context).length) return;
	    $("#data-table", context).floatThead({
	      floatContainerCss: {},
	      zIndex: function zIndex() {
	        return 999;
	      },
	      ariaLabel: function ariaLabel($table, $headerCell) {
	        return $headerCell.data("thlabel");
	      }
	    });
	  };

	  return function (context) {
	    setupSendemailModal(context);
	    setupHelptextModal(context);
	    setupDataTable(context);
	    setupFontAwesome();
	  };
	}(); //
	// setupUserPermission
	//


	var setupUserPermission = function () {
	  var setupModalNew = function setupModalNew(context) {
	    $("#modalnewtitle", context).on("hidden.bs.modal", function () {
	      $("#newtitle", context).val("");
	    });
	    $("#modalneworganisation", context).on("hidden.bs.modal", function () {
	      $("#neworganisation", context).val("");
	    });
	  };

	  var setupCloneAndRemove = function setupCloneAndRemove(context) {
	    $(document, context).on("click", ".cloneme", function () {
	      var parent = $(this).parents(".limit-to-view");
	      var cloned = parent.clone();
	      cloned.removeAttr("id").insertAfter(parent);
	    });
	    $(document, context).on("click", ".removeme", function () {
	      var parent = $(this).parents(".limit-to-view");

	      if (parent.siblings(".limit-to-view").length > 0) {
	        parent.remove();
	      }
	    });
	  };

	  return function (context) {
	    setupModalNew(context);
	    setupCloneAndRemove(context);
	  };
	}(); //
	// setupView
	//


	var setupView = function () {
	  var setupSelectAll = function setupSelectAll(context) {
	    if (!$(".col_check", context).length) return;
	    $("#selectall", context).click(function (event) {
	      $(".col_check", context).prop("checked", event.currentTarget.checked);
	    });
	  };

	  var setupGlobalChange = function setupGlobalChange(context) {
	    $("#global", context).change(function (event) {
	      $("#group_id_div", context).toggle(event.currentTarget.checked);
	    }).change();
	  };

	  var setupSorts = function setupSorts(context) {
	    var sortsEl = $("div#sorts", context);
	    if (!sortsEl.length) return;
	    sortsEl.on("click", ".closeme", function (event) {
	      var c = $(".request-row").length;
	      if (c < 1) return;
	      $(event.currentTarget).parents(".request-row").remove();
	    });
	    sortsEl.on("click", ".add", function (event) {
	      $(event.currentTarget).parents(".sort-add").before(sortsEl.data("sortrow"));
	    });
	  };

	  var setupGroups = function setupGroups(context) {
	    var groupsEl = $("div#groups", context);
	    if (!groupsEl.length) return;
	    groupsEl.on("click", ".closeme", function (event) {
	      if (!$(".request-row").length) return;
	      $(event.currentTarget).parents(".request-row").remove();
	    });
	    groupsEl.on("click", ".add", function (event) {
	      $(event.currentTarget).parents(".group-add").before(groupsEl.data("grouprow"));
	    });
	  };

	  var setupFilter = function setupFilter(context) {
	    var builderEl = $("#builder", context);
	    if (!builderEl.length) return;
	    if (!builderEl.data("use-json")) return;
	    var data = base64.decode(builderEl.data("base-filter"));
	    builderEl.queryBuilder("setRules", JSON.parse(data));
	  };

	  var setupUpdateFilter = function setupUpdateFilter(context) {
	    $("#saveview", context).click(function () {
	      var res = $("#builder", context).queryBuilder("getRules");
	      $("#filter", context).val(JSON.stringify(res, null, 2));
	    });
	  };

	  return function (context) {
	    setupSelectAll(context);
	    setupGlobalChange(context);
	    setupSorts(context);
	    setupGroups(context);
	    setupFilter(context);
	    setupUpdateFilter(context);
	  };
	}();

	var setupJSFromContext = function setupJSFromContext(context) {
	  var page = $('body').data('page');
	  setupBuilder(context);
	  setupCalendar(context);
	  setupEdit(context);
	  setupGlobe(context);

	  if (page == "data_graph") {
	    setupGraph(context);
	  }

	  setupLayout(context);
	  setupLogin(context);
	  setupMetric(context);
	  setupMyGraphs(context);
	  setupPlaceholder(context);
	  setupPopover(context);
	  setupPurge(context);
	  setupTable(context);
	  setupUserPermission(context);
	  setupView(context);
	};

	setupJSFromContext();

}());
