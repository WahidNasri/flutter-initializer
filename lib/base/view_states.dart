abstract class ViewState<T> {
  final T? data;

  const ViewState(this.data);

  bool get hasData => data != null;
}

class InitialViewState<T> extends ViewState<T> {
  const InitialViewState([super.data]);
}

class LoadingViewState<T> extends ViewState<T> {
  const LoadingViewState([super.data]);
}

class LoadedViewState<T> extends ViewState<T> {
  const LoadedViewState(T super.data);
}

class ErrorViewState<T> extends ViewState<T> {
  final dynamic error;

  const ErrorViewState(this.error) : super(null);
}
