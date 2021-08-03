import { injectors } from '@modusbox/redux-utils';
import { InjectableStore } from '@modusbox/redux-utils/lib/injectors/types';
import { composeWithDevTools } from 'redux-devtools-extension';
import { applyMiddleware, createStore, combineReducers } from 'redux';
import { routerMiddleware } from 'connected-react-router';
import { History } from 'history';
import createSagaMiddleware from 'redux-saga';
import createReducer from './createReducer';
import rootSaga from './sagas';

interface StoreConfig {
  isDevelopment: boolean;
}

export default function configure(
  history: History,
  // eslint-disable-next-line
  config: StoreConfig = {
    isDevelopment: process.env.NODE_ENV === 'development',
  },
): InjectableStore {
  const sagaMiddleware = createSagaMiddleware({});
  const staticReducers = createReducer(history);
  const middlewares = applyMiddleware(routerMiddleware(history), sagaMiddleware);
  const withInjectors = injectors.applyInjectors({
    staticReducers,
    sagaRunner: sagaMiddleware.run,
    rootSaga,
  });
  const composeEnhancers = composeWithDevTools({});
  const store = createStore(
    combineReducers(staticReducers),
    undefined,
    // @ts-ignore
    composeEnhancers(withInjectors, middlewares),
  );

  sagaMiddleware.run(rootSaga);

  return store as InjectableStore;
}
